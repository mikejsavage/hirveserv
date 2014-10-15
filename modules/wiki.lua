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
		sections = { },
	}

	for file in files:gmatch( "([^\n]+)" ) do
		table.insert( page.sections, loadPage( "%s/%s.txt" % { path, file } ) )
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
		local page = pages[ name ]

		if not page then
			client:msg( "No wiki entry for #ly%s#d.", name )
			return
		end

		if not page.sections then
			client:msg( "#lwShowing #ly%s#lw:\n#d%s", page.title, page.body )
			return
		end

		local output = "#ly%s#lw is split into #ly%d#lw sections:" % {
			page.title,
			#page.sections,
		}

		for i, section in ipairs( page.sections ) do
			output = output .. "\n    #ly%d #d- %s" % {
				i,
				section.title,
			}
		end

		client:msg( "%s", output )
	end,

	[ "^(%S+)%s+(%d+)$" ] = function( client, name, num )
		name = name:lower()
		num = tonumber( num )
		local page = pages[ name ]
		
		if not page then
			client:msg( "No wiki entry for #ly%s#d.", name )
			return
		end

		if not page.sections or not page.sections[ num ] then
			client:msg( "#lwBad section number." )
			return
		end

		local section = page.sections[ num ]

		client:msg( "#lwShowing #ly%s#lw: #ly%s #d(#lw%d#d of #lw%d#d)\n%s",
			page.title, section.title,
			num, #page.sections,
			section.body
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
