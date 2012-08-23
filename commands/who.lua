local function who( client )
	local output = "Cool people: #lwyou"

	for _, other in ipairs( chat.clients ) do
		if other ~= client and other.state == "chatting" then
			output = output .. " " .. other.name
		end
	end

	client:msg( output )
end

chat.command( "who", nil, who, "Shows who is online" )
chat.onAuth( who )
