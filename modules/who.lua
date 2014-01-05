local function who( client )
	local output = "Cool people: #lyyou"
	local alt = true

	for _, other in ipairs( chat.clients ) do
		if other ~= client and other.state == "chatting" then
			output = output .. " " .. ( alt and "#lm" or "#ly" ) .. other.name
			alt = not alt
		end
	end

	client:msg( "%s", output )
end

chat.command( "who", nil, who, "Shows who is online" )
chat.listen( "connect", who )
