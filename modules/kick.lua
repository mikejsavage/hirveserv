chat.command( "kick", "kick", {
	[ "^(%S+)%s*(.-)$" ] = function( client, name, reason )
		local target = chat.clientFromName( name )

		if target then
			if reason ~= "" then
				target:msg( "#lm%s#lw get stitches.", reason )
			end
			target:kill()

			if reason ~= "" then
				chat.msg( "#ly%s#lw was kicked by #ly%s#lw for #lm%s#lw.", target.name, client.name, reason )
			else
				chat.msg( "#ly%s#lw was kicked by #ly%s#lw.", target.name, client.name )
			end
		else
			client:msg( "There's nobody called #ly%s#d.", name )
		end
	end,
}, "<name>", "Kick someone from chat" )
