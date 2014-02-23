local function sendPM( silent )
	return function( client, name, message )
		local target = chat.clientFromName( name )

		if target then
			if target.user then
				target = target.user
			end

			target:msg( "PM from #ly%s#lw:#d %s", client.name, message )

			if not silent then
				client:msg( "PM to #ly%s#lw:#d %s", target.name, message )
			end
		else
			client:msg( "There's nobody called #ly%s#lw.", name )
		end
	end
end

chat.command( "pmsg", nil, {
	[ "^(%S+)%s+(.+)$" ] = sendPM( false ),
}, "<name> <message>", "Send a private message" )

chat.command( "qpmsg", "user", {
	[ "^(%S+)%s+(.+)$" ] = sendPM( true ),
}, "<name> <message>", "Send a private message that doesn't rep to you" )
