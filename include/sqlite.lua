require( "lsqlite3" )

local function newDB( file )
	local db, errCode, err = sqlite3.open( file )

	assert( db, err )

	local statementCache = { }

	getmetatable( db ).__call = function( self, query, ... )
		enforce( query, "query", "string", "function" )

		if type( query ) == "function" then
			self:exec( "BEGIN TRANSACTION" )

			query()

			self:exec( "COMMIT TRANSACTION" )
		else
			if not statementCache[ query ] then
				statementCache[ query ] = assert( ( self:prepare( query ) ), self:errmsg() )
			end

			local statement = statementCache[ query ]

			statement:reset()

			if ... then
				statement:bind_values( ... )
			end

			local iter = statement:urows()

			return function()
				return iter( statement )
			end
		end
	end

	return db
end

sqlite = {
	new = newDB,
}
