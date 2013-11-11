chat.listen( "connect", function( client )
	client:xmsg( "#ly%s#lw is in the house!", client.name )
end )

chat.listen( "disconnect", function( client )
	chat.msg( "#ly%s#lw left chat.", client.name )
end )
