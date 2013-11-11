chat.command( "roll", nil, function( client )
	chat.msg( "#ly%s#lw rolls! The dice come up... #lm%.1f#lw!", client.name, math.random( 10, 1000 ) / 10 )
end, "Roll a dice between 1 and 100" )
