chat.listen( "chat", function( from, message, recipients )
	for client, message in pairs( recipients ) do
		if client.user and client.user.settings.bren then
			recipients[ client ] = message:gsub( "%]", ">" )
		end
	end
end )

chat.command( "bren", "user", function( client )
	client.user.settings.bren = not client.user.settings.bren
	client.user:save()

	client:msg( "Brenmode %sabled.", client.user.settings.bren and "en" or "dis" )
end, "use this if you have an absolutely trash guard script" )
