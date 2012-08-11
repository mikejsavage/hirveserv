chat.command( "roll", nil, function( client )
	chat.msg( "#lw%s#d rolls! The dice come up... #lw%.1f#d!", client.name, math.random( 10, 1000 ) / 10 )
end, "Roll a dice between 1 and 100" )
