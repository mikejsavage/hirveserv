require( "lsqlite3" )

local function writeVersion( name, version )
	local versionFile = assert( io.open( "data/%s.version" % name, "w" ) )

	versionFile:write( version )
	versionFile:close()
end

local function loadSchema( db, name )
	local schema = assert( io.contents( "schema/%s.sql" % name ) )

	for query in schema:gmatch( "([^;]+)" ) do
		query = query:trim()

		if query ~= "" then
			db( query )()
		end
	end

	local version = 1
	while io.readable( "schema/upgrade-%s-%d.lua" % { name, version } ) do
		version = version + 1
	end

	writeVersion( name, version )
end

local function updateSchema( db, name )
	local version = io.contents( "data/%s.version" % name )

	if not version then
		version = 1
	elseif version:match( "^(%d+)$" ) then
		version = tonumber( version )
	else
		assert( false, "bad version number for %s" % name )
	end

	local upgradePath = "schema/upgrade-%s-%d.lua" % { name, version }
	while io.readable( upgradePath ) do
		assert( loadfile( upgradePath ) )( db )

		version = version + 1
		upgradePath = "schema/upgrade-%s-%d.lua" % { name, version }
	end

	writeVersion( name, version )
end

local function newDB( name )
	local path = "data/%s.sq3" % name
	local exists = io.readable( path )

	local db, errCode, err = sqlite3.open( "data/%s.sq3" % name )

	assert( db, err )

	local statementCache = { }

	getmetatable( db ).__call = function( self, query, ... )
		enforce( query, "query", "string", "function" )

		if type( query ) == "function" then
			self:exec( "BEGIN TRANSACTION" )

			local ok, err = pcall( query, self )

			if ok then
				self:exec( "COMMIT TRANSACTION" )
			else
				self:exec( "ROLLBACK TRANSACTION" )
				--assert( false, err )
			end
		else
			if not statementCache[ query ] then
				statementCache[ query ] = assert( ( self:prepare( query ) ), self:errmsg() )
			end

			local statement = statementCache[ query ]

			statement:reset()

			if ... then
				local ok, err = statement:bind_values( ... )
				--assert( ok == sqlite3.OK, self:errmsg() )
			end

			local iter = statement:urows()

			return function()
				return iter( statement )
			end
		end
	end

	if not exists then
		loadSchema( db, name )
	else
		updateSchema( db, name )
	end

	return db
end

sqlite = {
	new = newDB,
}
