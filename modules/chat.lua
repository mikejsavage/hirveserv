local modules = require( "include.modules" )

local function handleChat( from, message )
	local recipients = { }

	for _, client in ipairs( chat.clients ) do
		if client ~= from and client.state == "chatting" then
			recipients[ client ] = message
		end
	end

	chat.event( "chat", from, message, recipients )

	for client, newMessage in pairs( recipients ) do
		client:send( "chat", newMessage )
	end
end

local function handleNameChange( client, newName )
	client:xmsg( "#ly%s#lw changed their name to #ly%s#lw.", client.name, newName )

	chat.event( "nameChange", client, newName )

	client.name = newName
	client.lower = newName:lower()

	table.removeValue( chat.clients, client )
	table.insertBy( chat.clients, client, function( other )
		return client.lower < other.lower
	end )
end

local function handlePM( client, message, silent )
	if not message then
		return false
	end

	local name, args = message:match( "^%s*(%S*)%s*(.*)$" )
	local command = modules.getCommand( name )

	if not command or not client:hasPriv( command.priv ) then
		if not silent then
			client:msg( "Huh? #lm%s#lw me #lyhelp#lw if you're stuck.", client.pmSyntax )
		end

		return false
	end

	local badSyntax = true

	for _, callback in ipairs( command.callbacks ) do
		local ok, err, subs = pcall( string.gsub, args, callback.pattern, function( ... )
			callback.callback( client, ... )
		end )

		if not ok then
			log.error( "Command(%s,%s) callback failed: %s", client.name, name, err )

			return true
		end

		if subs ~= 0 then
			badSyntax = false

			break
		end
	end

	if badSyntax then
		client:msg( "Syntax: %s %s", name, command.syntax )
	end

	return true
end

chat.handler( "chat", { "chat", "pm", "nameChange" }, function( client )
	client.state = "chatting"

	chat.event( "connect", client )

	local enter = os.time()

	while true do
		local command, args = coroutine.yield()

		if command == "chat" then
			local wasPM = false

			if client.user and client.user.settings.alias then
				local stripped = args:stripVT102()

				local trimmed = stripped:match( "^\n?" .. client.name .. "%s*(.-)\n?$" ) or stripped
				local message = trimmed:match( client.user.settings.alias )

				if message then
					local pm = message:match( "^!(.*)$" )

					if pm then
						local top = client:handler( "pm" )

						if coroutine.running() ~= top then
							client:onCommand( "pm", pm )

							wasPM = true
						elseif handlePM( client, pm, true ) then
							wasPM = true
						end
					end
				end
			end

			if not wasPM then
				handleChat( client, args )
			end
		elseif command == "pm" then
			handlePM( client, args )
		elseif command == "nameChange" then
			handleNameChange( client, args )
		end
	end
end )

local function findAliasPattern( message, needle )
	local left, right = message:match( "^(.-)" .. needle .. "(.-)$" )

	if not left then
		return nil
	end

	local leftTrimmed, leftWhitespace = left:match( "^(.-)(%s*)$" )
	local rightWhitespace, rightTrimmed = right:match( "^(%s*)(.-)$" )

	local leftOutline = leftTrimmed:gsub( "%P+", "<junk>" ) .. leftWhitespace
	local rightOutline = rightWhitespace .. rightTrimmed:gsub( "%P+", "<junk>" )

	local outline = leftOutline .. "<your message>" .. rightOutline

	local pattern = "^" .. leftOutline:patternEscape():gsub( "<junk>", ".-" )
		.. "(.*)"
		.. rightOutline:patternEscape():gsub( "<junk>", ".-" ) .. "$"

	return pattern, outline
end

chat.handler( "needle", { "chat", "pm" }, function( client, needle )
	client:msg( "Use your chat script (#lwch#d, #lmcx#lw etc) to send #ly%s#d!", needle )

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			client:msg( "Say #ly%s#d to #lweveryone#d and not just me.", needle )
		end

		if command == "chat" then
			args = args:match( "^\n?" .. client.name .. "%s*(.-)\n?$" ) or args
			args = args:stripVT102()

			local pattern, outline = findAliasPattern( args, needle )

			if not pattern then
				client:msg( "Whine at Hirve." )

				break
			end

			client:msg( "It looks like your chats are of the form:" )
			client:msg( "%s #lw%s", client.name, outline )
			client:msg( "If this is wrong then whine at Hirve." )

			client.user.settings.alias = pattern
			client.user:save()

			break
		end
	end
end )

chat.command( "alias", "user", {
	[ "^$" ] = function( client )
		local letters = "abcdefghi"
		local needle = ""

		for i = 1, 4 do
			local idx = math.random( 9 )
			needle = needle .. ( i % 2 == 0 and idx or letters:sub( idx, idx ) )
		end

		client:pushHandler( "needle", needle )
	end,

	[ "^(.+)$" ] = function( client, pattern )
		client.user.settings.alias = pattern
		client.user:save()
	end,
}, "[pattern]", "Register your chat script so you can `cx !cmd` as shorthand" )
