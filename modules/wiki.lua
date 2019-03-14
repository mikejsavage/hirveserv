local pages
local sections

local function loadPage( path )
	local page = assert( io.contents( path ) )
	local title, body = page:match( "^([^\n]+)\n+(.+)$" )

	return {
		title = title,
		body = body,
	}
end

local function checkClash( name )
	assert( not pages[ name ], "name clash: %s" % name )
end

local function addPage( section, path, name )
	if not name then
		return
	end

	checkClash( name )

	pages[ name ] = loadPage( path, name )
	pages[ name ].name = name
	table.insert( sections[ section ].pages, name )
end

local function addMultiPage( section, path, name )
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
	table.insert( sections[ section ].pages, name )
end

local function loadSection()
	local contents = io.contents( chat.config.dataDir .. "/wiki/sections.txt" )
	if not contents then
		table.insert( sections, { pages = { } } )
		return { }, 1
	end

	local map = { }
	local default = 1

	for line in contents:gmatch( "([^\n]+)" ) do
		if line:find( ":" ) then
			if sections[ #sections ] and #sections[ #sections ].pages == 0 then
				default = #sections
			end
			table.insert( sections, { title = line, pages = { } } )
		elseif line ~= "" then
			map[ line ] = #sections
		end
	end

	return map, default
end

local function buildWiki()
	pages = { }
	sections = { }

	if not io.readable( chat.config.dataDir .. "/wiki" ) then
		return
	end

	local secMap, defaultSection = loadSection()

	for file in lfs.dir( chat.config.dataDir .. "/wiki" ) do
		if file:sub( 1, 1 ) ~= "." and file ~= "sections.txt" then
			local fullPath = "%s/wiki/%s" % { chat.config.dataDir, file }
			local attr = lfs.attributes( fullPath )

			file = file:lower()

			if attr.mode == "directory" then
				addMultiPage( secMap[ file ] or defaultSection, fullPath, file )
			else
				local name = file:match( "^(.+)%.txt$" )
				addPage( secMap[ name ] or defaultSection, fullPath, name )
			end
		end
	end

	for _, section in ipairs( sections ) do
		table.sort( section.pages )
	end
end

chat.command( "wiki", "user", {
	[ "^$" ] = function( client )
		local output = { "#lwWiki:" }

		for _, section in ipairs( sections ) do
			if section.title then
				if section ~= sections[ 1 ] then
					table.insert( output, "" )
				end
				table.insert( output, "#lw%s" % section.title )
				table.insert( output, "" )
			end
			for _, name in ipairs( section.pages ) do
				local page = pages[ name ]
				table.insert( output, "    #ly%s #d- %s" % { page.name, page.title } )
			end
		end

		client:msg( output )
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
			output = output .. "\n    #ly%s %d #d- %s" % {
				name,
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
}, "<page> [subpage]", "Super duper wiki" )

local function searchString( str, needle )
	return str:lower():find( needle, 1, true )
end

local function searchPage( page, needle )
	local res = "    #ly%s#d - %s" % { page.name, page.title }

	if searchString( page.name, needle ) then
		return res
	end

	if searchString( page.title, needle ) then
		return res
	end

	if page.sections then
		for i, section in ipairs( page.sections )  do
			if searchString( section.body, needle ) then
				return "    #ly%s %d#d - %s" % { page.name, i, section.title }
			end
		end
	elseif searchString( page.body, needle ) then
		return res
	end
end

local function search( needle )
	local results = { }

	for _, section in ipairs( sections ) do
		for _, name in ipairs( section.pages ) do
			local res = searchPage( pages[ name ], needle )
			if res then
				table.insert( results, res )
				if #results >= 10 then
					return results, true
				end
			end
		end
	end

	return results
end

chat.command( "search", "user", function( client, needle )
	local results, truncated = search( needle:lower() )
	table.sort( results )

	if #results == 0 then
		client:msg( "#lwCouldn't find anything about #ly%s", needle )
		return
	end

	table.insert( results, 1, "#lwResults for #ly%s#lw:" % needle )
	if truncated then
		table.insert( results, "#lwToo many results. Try to be more specific!" )
	end

	client:msg( results )
end, "Search wiki" )

chat.command( "rebuildwiki", "all", function( client )
	local oldPages = pages
	local oldSections = sections

	local ok, err = chat.pcall( buildWiki )

	if not ok then
		client:msg( "Rebuild failed! %s", err )
		pages = oldPages
		sections = oldSections
	else
		client:msg( "Rebuilt." )
	end
end, "Rebuild the wiki" )

buildWiki()
