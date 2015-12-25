local json = require( "cjson.safe" )

lfs.mkdir( "data/board" )

local PostsPerPage = 8

local posts = { }

while true do
	local i = #posts + 1
	local post = io.contents( "data/board/%d.json" % i )
	if not post then
		break
	end

	posts[ i ] = json.decode( post )
end

local prompts = { }

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

	for _, tag in ipairs( tags ) do
		title = title .. tagColour( tag ) .. " ##" .. tag
	end

	return title
end

local function getHeader( post, id )
	return "#ly%4d #lc%s #lg%12s #lw%s" % {
		id,
		os.date( "%e %b %y", post.date ),
		post.author,
		getNiceTitle( post.title, post.tags ),
	}
end

local function showBoard( client, page )
	local output = { "#lwBulletin board:" }

	local first = #posts - PostsPerPage * ( page - 1 )
	local last = math.max( 1, ( first - PostsPerPage ) + 1 )

	for i = first, last, -1 do
		table.insert( output, getHeader( posts[ i ], i ) )
	end

	if ( first - last ) + 1 == PostsPerPage and posts[ page * PostsPerPage + 1 ] then
		table.insert( output, "#lyread p%d#lw for more" % ( page + 1 ) )
	end

	client.user.settings.lastRead = os.time()
	client.user:save()

	prompts[ client.user ] = nil

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
	local title, tags = args:match( "^([^#]+)(.*)$" )

	if not title then
		client:msg( "Syntax: post <title> [##tag1 ##tag2 ...]" )

		return
	end

	client:pushHandler( "editor", function( body )
		if not body then
			return
		end

		title = title:trim()

		local post = {
			author = client.user.name,
			date = os.time(),
			title = title,
			tags = { },
			body = body,
		}

		local tagsMap = { }
		for tag in tags:gmatch( "#(%S+)" ) do
			tagsMap[ tag ] = true
		end
		for tag in pairs( tagsMap ) do
			table.insert( post.tags, tag )
		end
		table.sort( post.tags )

		io.writeFile( "data/board/%d.json" % ( #posts + 1 ), json.encode( post ) )
		posts[ #posts + 1 ] = post

		table.clear( prompts )

		chat.msg( "#ly%s#lw added a new post: #lm%s", client.user.name, getNiceTitle( title, post.tags ) )
	end )
end, "Post a message to the bulletin board" )

chat.prompt( function( client )
	if client.user and not prompts[ client.user ] then
		local setPrompt = #posts > 0 and posts[ #posts ].date > ( client.user.settings.lastRead or 0 )

		if #posts > 0 and client.user.settings.lastRead then
			setPrompt = posts[ #posts ].date > client.user.settings.lastRead
		end

		prompts[ client.user ] = setPrompt and "#ly[READ]" or ""
	end

	return prompts[ client.user ]
end )
