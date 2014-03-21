local lfs = require( "lfs" )

local MaxResults = 10

local considers = { }

lfs.mkdir( "data/consider" )

local colours = {
	acid = "#g",
	cold = "#lb",
	evil = "\27[1;30m",
	fire = "#lr",
	good = "#lg",
	holy = "#lw",
	lightning = "#ly",
	poison = "#y",
	pressure = "#lc",
}

local function niceConsider( consider )
	local output = { "#lw%s #ly[%s]" % { consider.name, consider.zone } }

	if consider.align then
		table.insert( output, "#d" .. consider.align )
	end

	if consider.weak then
		table.insert( output, "#dWeak against: " .. consider.weak )
	end

	if consider.strong then
		table.insert( output, "#dStrong against: " .. consider.strong )
	end

	table.insert( output, "" )

	return table.concat( output, "\n" )
end

local function addResists( consider, key, line )
	local resists = { }

	for resist in line:gmatch( "(%u%u+)" ) do
		table.insert( resists, colours[ resist:lower() ] .. resist )
	end

	consider[ key ] = table.concat( resists, " " )
end

local function buildConsiders()
	for f in lfs.dir( "data/consider" ) do
		if f:match( "%.txt$" ) then
			local zone = assert( io.contents( "data/consider/" .. f ) )
			local name, mobs = zone:match( "^([^\n]+)\n\n(.+)$" )

			assert( name, "Bad zone: " .. f )

			for mob in ( mobs .. "\n\n" ):gmatch( "(.-)\n\n" ) do
				local consider = { zone = name }

				for line in mob:gmatch( "([^\n]+)" ) do
					if not consider.name then
						consider.name = line
						consider.lower = line:lower()
					else
						if line:match( "^Strong against:" ) then
							addResists( consider, "strong", line )
						elseif line:match( "^Weak against:" ) then
							addResists( consider, "weak", line )
						else
							consider.align = line
						end
					end
				end

				assert( consider.name, "No name in: " .. f )

				table.insert( considers, consider )
			end
		end
	end
end

chat.command( "consider", "user", function( client, name )
	name = name:lower()

	local output = { "Searching considers for #lm%s#lw:" % name }

	for _, consider in ipairs( considers ) do
		if consider.lower:find( name, 1, true ) then
			if #output >= MaxResults then
				table.insert( output, "#lwToo many results. Try to be more specific!" )

				break
			end

			table.insert( output, niceConsider( consider ) )
		end
	end

	client:msg( output )
end, "Search consider database" )

chat.command( "rebuildconsider", "all", function( client )
	considers = { }

	local ok, err = pcall( buildConsiders )

	if not ok then
		client:msg( "Rebuild failed! %s", err )
	else
		client:msg( "Rebuilt." )
	end
end, "Rebuild considers database" )

buildConsiders()
