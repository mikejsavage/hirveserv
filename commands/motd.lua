local motd = ""

chat.command( "motd", "", function( client )
	client:msg( motd )
end, "Show message of the day" )

chat.command( "setmotd", "motd", function( client, args )
	motd = args:gsub( "\\n", "\n" )

	chat.msg( "MOTD! %s", motd )
end, "Update motd" )

chat.listen( "connect", function( client )
	if motd ~= "" then
		client:msg( motd )
	end
end )
