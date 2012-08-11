local Logs = { }

chat.command( "log", nil, {
	[ "^(%d+)$" ] = function( client, messages )
	end,

	[ "^(%D.*)$" ] = function( client, needle )
	end,

	[ "^(%d+) (%S+)$" ] = function( client, messages, needle )
	end,
}, "<number/needle> [needle]", "Show recent messages" )
