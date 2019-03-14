chat.listen( "chat", function( from, message, recipients )
	for client, message in pairs( recipients ) do
		if client.user and client.user.settings.bren then
			recipients[ client ] = message:gsub( "%]", ">" )
		end

		if client.user and client.user.settings.bren2 then
			recipients[ client ] = "\027[0m" .. message:stripVT102()
		end
	end
end )

chat.command( "bren", "user", function( client )
	client.user.settings.bren = not client.user.settings.bren
	client.user:save()

	client:msg( "Brenmode %sabled.", client.user.settings.bren and "en" or "dis" )
end, "use this if you have an absolutely trash guard script" )

chat.command( "bren2", "user", function( client )
	client.user.settings.bren2 = not client.user.settings.bren2
	client.user:save()

	client:msg( "2.Brenmode %sabled.", client.user.settings.bren2 and "en" or "dis" )
end, "toggle colourless chat so you can play from work" )
