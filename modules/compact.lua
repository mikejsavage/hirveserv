chat.listen( "chat", function( from, message, recipients )
	for client, message in pairs( recipients ) do
		if client.user and client.user.settings.compact then
			recipients[ client ] = message:trim()
		end
	end
end )

chat.command( "compact", "user", function( client )
	client.user.settings.compact = not client.user.settings.compact
	client.user:save()

	client:msg( "Compact chat %sabled.", client.user.settings.compact and "en" or "dis" )
end, "Toggle compact chat" )
