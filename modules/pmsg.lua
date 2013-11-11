chat.command( "pmsg", nil, {
	[ "^(%S+)%s+(.+)$" ] = function( client, name, message )
		local target = chat.clientFromName( name )

		if target then
			target:msg( "PM from #ly%s#lw:#d %s", client.name, message )
			client:msg( "PM to #ly%s#lw:#d %s", target.name, message )
		else
			client:msg( "There's nobody called #ly%s#lw.", name )
		end
	end,
}, "<name> <message>", "Send a private message" )
