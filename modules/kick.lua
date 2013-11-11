chat.command( "kick", "kick", {
	[ "^(%S+)$" ] = function( client, name )
		local target = chat.clientFromName( name )

		if target then
			target:kill()

			chat.msg( "#ly%s#d was kicked by #ly%s#d.", target.name, client.name )
		else
			client:msg( "There's nobody called #ly%s#d.", name )
		end
	end,
}, "<name>", "Kick someone from chat" )
