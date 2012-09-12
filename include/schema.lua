return setmetatable( { }, {
	__index = function( self, key )
		local schema = assert( io.contents( "schema/%s.sql" % key ) )

		return function( db )
			for query in schema:gmatch( "([^;]+)" ) do
				query = query:trim()

				if query ~= "" then
					db( query )()
				end
			end
		end
	end,
} )
