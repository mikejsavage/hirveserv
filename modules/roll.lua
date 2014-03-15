chat.command( "roll", nil, function( client )
	chat.msg( "#ly%s#lw rolls! The dice come up... #lm%.1f#lw!", client.name, math.random( 0, 1009 ) / 10 )
end, "Roll a dice between 0.0 and 100.9" )
