chat.command( "pmsg", nil, {
	[ "^(%S+)%s+(.+)$" ] = function( client, name, message )
		local target = chat.clientFromName( name )

		if target then
			target:msg( "PM from #ly%s#d: %s", client.name, message )
			client:msg( "PM to #ly%s#d: %s", target.name, message )
		else
			client:msg( "There's nobody called #ly%s#d.", name )
		end
	end,
}, "<name> <message>", "Send someone a private message" )
