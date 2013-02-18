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

local function needleHandler( client, needle )
	client:msg( "Use your chat script (#lwch#d, #lwcx#d etc) to send #ly%s#d!", needle )

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			client:msg( "Say #ly%s#d to #lweveryone#d and not just me.", needle )
		end

		if command == "all" then
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

			chat.db.users( "INSERT INTO settings ( userid, setting, value ) VALUES ( ?, 'alias', ? )", client.userID, pattern )()

			client.settings.alias = pattern

			break
		end
	end
end

chat.command( "alias", "user", {
	[ "^$" ] = function( client )
		local letters = "abcdefghi"
		local needle = ""

		for i = 1, 4 do
			local idx = math.random( 9 )
			needle = needle .. ( i % 2 == 0 and idx or letters:sub( idx, idx ) )
		end

		client:pushHandler( needleHandler, needle )
	end,

	[ "^(.+)$" ] = function( client, pattern )
		client.settings.alias = pattern
	end,
}, "[pattern]", "Register your chat script so you can cx !cmd as shorthand" )
