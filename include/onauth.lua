local OnAuths = { }

local function doOnAuths( client )
	for _, callback in ipairs( OnAuths ) do
		callback( client )
	end
end

function chat.onAuth( callback )
	enforce( callback, "callback", "function" )

	table.insert( OnAuths, callback )
end

return {
	doOnAuths = doOnAuths,
}
