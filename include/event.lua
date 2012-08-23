local Events = { }

function chat.listen( name, callback )
	enforce( name, "name", "string" )
	enforce( callback, "callback", "function" )

	if not Events[ name ] then
		Events[ name ] = { }
	end

	table.insert( Events[ name ], callback )
end

function chat.event( name, ... )
	enforce( name, "name", "string" )

	if Events[ name ] then
		for _, callback in ipairs( Events[ name ] ) do
			callback( ... )
		end
	end
end
