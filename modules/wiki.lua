local EntriesPerPage = 10

local pages = { }
local pagesList = { }

local function checkClash( name )
	assert( not pages[ name ], "name clash: %s" % name )
end

local function loadPage( path )
	local page = assert( io.contents( path ) )
	local title, body = page:match( "^([^\n]+)\n+(.+)$" )

	return {
		title = title,
		body = body,
	}
end

local function addPage( path, name )
	if not name then
		return
	end

	checkClash( name )

	pages[ name ] = loadPage( path, name )
	pages[ name ].name = name
	table.insert( pagesList, name )
end

local function addMultiPage( path, name )
	local info = assert( io.contents( "%s/%s.txt" % { path, name } ) )
	local title, files = info:match( "^([^\n]+)%s+(.+)$" )

	local page = {
		name = name,
		title = title,
		pages = { },
	}

	for file in files:gmatch( "([^\n]+)" ) do
		table.insert( page.pages, loadPage( "%s/%s.txt" % { path, file } ) )
	end

	checkClash( name )

	pages[ name ] = page
	table.insert( pagesList, name )
end

local function buildWiki()
	if not io.readable( "data/wiki" ) then
		return
	end

	for file in lfs.dir( "data/wiki" ) do
		if file ~= "." and file ~= ".." then
			local fullPath = "data/wiki/" .. file
			local attr = lfs.attributes( fullPath )

			file = file:lower()

			if attr.mode == "directory" then
				addMultiPage( fullPath, file )
			else
				local name = file:match( "^(.+)%.txt$" )

				addPage( fullPath, name )
			end
		end
	end

	table.sort( pagesList )
end

chat.command( "wiki", "user", {
	[ "^$" ] = function( client )
		local output = "#lwThe wiki has the following entries:"

		for _, name in ipairs( pagesList ) do
			local page = pages[ name ]

			output = output .. "\n    #ly%s #d- %s" % {
				page.name,
				page.title,
			}
		end

		client:msg( "%s", output )
	end,

	[ "^(%S+)$" ] = function( client, name )
		name = name:lower()

		if not pages[ name ] then
			client:msg( "No wiki entry for #ly%s#d.", name )

			return
		end

		if not pages[ name ].pages then
			client:msg( "#lwShowing #ly%s#lw:\n#d%s", name, pages[ name ].body )

			return
		end

		local output = "#ly%s#lw is split into #ly%d#lw pages:" % {
			name,
			#pages[ name ].pages,
		}

		for i, page in ipairs( pages[ name ].pages ) do
			output = output .. "\n    #ly%d #d- %s" % {
				i,
				page.title,
			}
		end

		client:msg( "%s", output )
	end,

	[ "^(%S+)%s+(%d+)$" ] = function( client, name, page )
		name = name:lower()
		page = tonumber( page )
		
		if not pages[ name ] then
			client:msg( "No wiki entry for #ly%s#d.", name )

			return
		end

		if not pages[ name ].pages or not pages[ name ].pages[ page ] then
			client:msg( "#lwBad page number." )

			return
		end

		client:msg( "#lwShowing #ly%s#lw: #ly%s #d(#lw%d#d of #lw%d#d)\n%s",
			name, pages[ name ].pages[ page ].title,
			page, #pages[ name ].pages,
			pages[ name ].pages[ page ].body
		)
	end,
}, "<category/page> [page] [search]", "Super duper wiki" )

chat.command( "rebuildwiki", "all", function( client )
	pages = { }
	pagesList = { }

	local ok, err = pcall( buildWiki )

	if not ok then
		client:msg( "Rebuild failed! %s", err )
	else
		client:msg( "Rebuilt." )
	end
end, "Rebuild the wiki" )

buildWiki()
