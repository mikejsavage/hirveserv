local Logs = { }

local function sendLogs( client, messages, needle )
	messages = math.min( tonumber( messages ) or 20, 50 )
	needle = needle and needle:lower() or ""

	local output = { }
	local i = #Logs
	local n = 0

	while i >= 1 and n < messages do
		if needle == "" or Logs[ i ].lower:find( needle, 1, true ) then
			table.insert( output, 1, Logs[ i ].normal )

			n = n + 1
		end

		i = i - 1
	end

	if needle == "" then
		client:msg( "Last #lw%d#d message%s:\n%s", n, string.plural( n ), table.concat( output, "\n" ) )
	else
		client:msg( "Last #lw%d#d message%s containing #lw%s#d:\n%s", n, string.plural( n ), needle, table.concat( output, "\n" ) )
	end
end

local function addLog( message )
	table.insert( Logs, {
		normal = os.date( "#lr[#lw%H:%M#lr] " ) .. message:gsub( "#", "##" ),
		lower = message:lower(),
	} )
end

local function addMsg( message )
	message = "<%s> %s" % { chat.config.name, message }

	table.insert( Logs, {
		normal = os.date( "#lr[#lw%H:%M#lr] " ) .. message,
		lower = message:lower(),
	} )
end

chat.command( "log", nil, {
	[ "^$" ] = function( client )
		sendLogs( client )
	end,

	[ "^(%d+)$" ] = function( client, messages )
		sendLogs( client, messages )
	end,

	[ "^(%D.*)$" ] = function( client, needle )
		sendLogs( client, nil, needle )
	end,

	[ "^(%d+)%s+(.+)$" ] = function( client, messages, needle )
		sendLogs( client, messages, needle )
	end,
}, "<number/needle> [needle]", "Show recent messages" )

chat.listen( "message", function( client, message )
	addLog( message:trim() )
end )

chat.listen( "connect", function( client )
	addMsg( "#lw%s#d is in the house!" % client.name )
end )

chat.listen( "nameChange", function( client, newName )
	addMsg( "#lw%s#d changed their name to #lw%s#d." % { client.name, newName } )
end )

chat.listen( "disconnect", function( client )
	addMsg( "#lw%s#d left chat." % client.name )
end )
