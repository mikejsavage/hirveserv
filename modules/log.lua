local logs = { }

local defaultLines = 20
local maxLines = 200

local function sendLogs( client, messages, needle )
	messages = math.min( tonumber( messages ) or defaultLines, maxLines )
	needle = needle and needle:lower() or ""

	local output = { }
	local i = #logs
	local n = 0

	while i >= 1 and n < messages do
		if needle == "" or logs[ i ].lower:find( needle, 1, true ) then
			table.insert( output, 1, logs[ i ].normal )

			n = n + 1
		end

		i = i - 1
	end

	if needle == "" then
		client:msg( "Last #ly%d#lw message%s:", n, string.plural( n ) )
	else
		client:msg( "Last #ly%d#lw message%s containing #lm%s#d:", n, string.plural( n ), needle )
	end

	for _, msg in ipairs( output ) do
		client:msg( "%s", msg )
	end
end

local function addLog( message )
	table.insert( logs, {
		normal = os.date( "#lr[#lw%H:%M#lr] " ) .. message:gsub( "#", "##" ),
		lower = message:lower():stripVT102(),
	} )

	if #logs > chat.config.logLines then
		table.remove( logs, 1 )
	end
end

local function addMsg( message )
	message = "<%s> %s" % { chat.config.name, message }

	table.insert( logs, {
		normal = os.date( "#lr[#lw%H:%M#lr] " ) .. message,
		lower = message:lower():stripVT102(),
	} )

	if #logs > chat.config.logLines then
		table.remove( logs, 1 )
	end
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

chat.listen( "chat", function( from, message )
	addLog( message:trim() )
end )

chat.listen( "msg", addMsg )
