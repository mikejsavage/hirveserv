require( "tokyocabinet" )

local PostsPerPage = 8

local posts = tokyocabinet.tdbnew()

posts:setxmsiz( 8 * 1024 )
posts:open( "data/posts.tct", posts.OWRITER + posts.OCREAT )
posts:setindex( "date", posts.ITDECIMAL + posts.ITKEEP )

local tagColours = { "r", "g", "b", "y", "c", "m" }

local function tagColour( tag )
	local total = 0

	for i = 1, tag:len() do
		total = total + tag:byte( i )
	end

	return "#l" .. tagColours[ ( total % #tagColours ) + 1 ]
end

local function getNiceTitle( title, tags )
	title = title:gsub( "#", "##" )

	if type( tags ) == "table" then
		for _, tag in ipairs( tags ) do
			title = title .. tagColour( tag ) .. " ##" .. tag
		end
	else
		for tag in tags:gmatch( "(%S+)" ) do
			title = title .. tagColour( tag ) .. " ##" .. tag
		end
	end

	return title
end

local function getHeader( post, id )
	return "#ly%4d #lc%s #lg%12s #lw%s" % {
		id,
		os.date( "%e %b", post.time ),
		post.author,
		getNiceTitle( post.title, post.tags ),
	}
end

chat.handler( "post", { "editor" }, function( client, title, tags )
	client:pushHandler( "editor" )

	local _, body = coroutine.yield()

	if not body then
		client:msg( "Nevermind." )

		return
	end

	local id = posts:genuid()
	posts[ id ] = {
		author = client.user.name,
		date = os.time(),
		tags = table.concat( tags, " " ),
		title = title,
		body = body,
	}
	posts:sync()

	chat.msg( "#ly%s#lw added a new post: #lm%s", client.user.name, getNiceTitle( title, tags ) )
end )

local function showBoard( client, page )
	local query = tokyocabinet.tdbqrynew( posts )

	query:setorder( "", query.QONUMDESC )
	query:setlimit( PostsPerPage, ( page - 1 ) * PostsPerPage )

	local result = query:search()
	local output = { "#lwBulletin board:" }

	for _, id in ipairs( result ) do
		local post = posts[ id ]

		table.insert( output, getHeader( post, id ) )
	end

	if #result == PostsPerPage and posts[ page * PostsPerPage + 1 ] then
		table.insert( output, "#lyread p%d#lw for more" % ( page + 1 ) )
	end

	client:msg( "%s", table.concat( output, "\n" ) )
end

local function showPost( client, id )
	local post = posts[ id ]

	if not post then
		client:msg( "No such post." )

		return
	end

	client:msg( "#lwBulletin board:\n%s\n\n#d%s\n", getHeader( post, id ), post.body )
end

chat.command( "read", "user", {
	[ "^$" ] = function( client )
		showBoard( client, 1 )
	end,

	[ "^p(%d+)$" ] = function( client, page )
		showBoard( client, tonumber( page ) )
	end,

	[ "^(%d+)$" ] = function( client, id )
		showPost( client, tonumber( id ) )
	end,
}, "<post/p1/p2/etc>", "Look at the bulletin board" )

chat.command( "post", "user", function( client, args )
	local title, tagsStr = args:match( "^([^#]+)(.*)$" )

	if not title then
		client:msg( "Syntax: post <title> [#tag1 #tag2 ...]" )

		return
	end

	local tagsMap = { }
	local tags = { }

	for tag in tagsStr:gmatch( "#(%S+)" ) do
		tagsMap[ tag ] = true
	end

	for tag in pairs( tagsMap ) do
		table.insert( tags, tag )
	end

	table.sort( tags )

	client:pushHandler( "post", title:trim(), tags )
end, "Post a message to the bulletin board" )

chat.listen( "reload", function()
	posts:close()
end )
