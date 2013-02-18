local Protocols = {
	mm = require( "protocols.mm" ),
	zmud = require( "protocols.zmud" ),
}

local userCount = chat.db.users( "SELECT COUNT( * ) FROM users" )()
local adminCode

if userCount == 0 then
	adminCode = bcrypt.salt( 1 ):match( "([^$]+)$" )

	print( chat.parseColours( "Use the password #lw%s#d to create admin account" % adminCode ) )
end

local function chatHandler( client )
	client.state = "chatting"
	chat.msg( "#lw%s#d is in the house!", client.name )

	chat.event( "connect", client )

	while true do
		local command, args = coroutine.yield()

		if command == "all" then
			local pm

			if client.settings.alias then
				local stripped = args:stripVT102()

				local trimmed = stripped:match( "^\n?" .. client.name .. "%s*(.-)\n?$" ) or stripped
				local message = trimmed:match( client.settings.alias )

				if message then
					pm = message:match( "^!([^!].*)$" )

					if pm then
						client:pm( pm )
					end
				end
			end

			if not pm then
				client:chatAll( args )
			end
		elseif command == "pm" then
			client:pm( args )
		elseif command == "nameChange" then
			client:nameChange( args )
		end
	end
end

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

local function oldregistrationHandler( client )
	local state = "password"

	local password
	local ipAuth
	local aliasPattern
	local createAccount = false

	local letters = "abcdefghi"
	local aliasNeedle = ""

	for i = 1, 4 do
		local idx = math.random( 9 )
		aliasNeedle = aliasNeedle .. ( i % 2 == 0 and idx or letters:sub( idx, idx ) )
	end

	while true do
		if state == "password" then
			client:msg( "What do you want your #lwactual password#d to be?" )
		elseif state =="ipauth" then
			client:msg( "Do you want #lwIP auth#d enabled for the PC (y/n)?" )
			client:msg( "(this means you will autologin from here - don't use it on a shared computer)" )
		elseif state == "alias" then
			client:msg( "One more thing, #lwchatall#d (use your #lwchat alias#d if you have one) #lw%s#d.", aliasNeedle )
		elseif state == "aliasVerify" then
			client:msg( "Does that look right (y/n)?" )
		end

		local command, args = coroutine.yield()

		if command == "nameChange" then
			client:msg( "Don't do that..." )
			client:kill()

			break
		end

		if command == "pm" then
			if state == "password" then
				password = args

				state = "ipauth"
			elseif state == "ipauth" then
				local yn = args:yn()

				if yn == "y" then
					ipAuth = client.socket:getpeername()

					state = "alias"
				elseif yn == "n" then
					state = "alias"
				end
			elseif state == "alias" or state == "alias2" then
				client:msg( "#lwchatall %s#d, not PM!", aliasNeedle )

				-- don't spam them
				state = "alias2"
			elseif state == "aliasVerify" then
				local yn = args:yn()

				if yn == "y" then
					client:msg( "Ok! You can now send commands by prefixing chats with #lw/#d." )
					client:msg( "For example, #lwchat /help#d is the same as PMing me #lwhelp#d." )
					client:msg( "If you ever change your chat alias, you'll need to let me know. PM me #lwhelp alias#d for details." )

					createAccount = true

					break
				elseif yn == "n" then
					client:msg( "Nevermind. PM me #lwhelp alias#d if you want to set this up manually." )

					createAccount = true

					break
				end
			end
		end

		if command == "all" then
			if state == "alias" or state == "alias2" then
				args = args:match( "^\n?" .. client.name .. "%s*(.-)\n?$" ) or args
				args = args:stripVT102()

				local pattern, outline = findAliasPattern( args, aliasNeedle )

				if not pattern then
					client:msg( "Nevermind. PM me #lwhelp alias#d if you want to set this up manually." )

					createAccount = true

					break
				else
					client:msg( "It looks like your chats are of the form:" )
					client:msg( "%s #lw%s", client.name, outline )

					aliasPattern = pattern

					state = "aliasVerify"
				end
			end
		end
	end

	if createAccount then
		local salt = bcrypt.salt( chat.config.bcryptRounds )
		local digest = bcrypt.digest( password, salt )

		chat.db.users( function()
			chat.db.users( "INSERT INTO users ( name, password ) VALUES ( ?, ? )", client.name:lower(), digest )()
			
			local userID = chat.db.users( "SELECT last_insert_rowid()" )()

			if client.privs.all then
				chat.db.users( "INSERT INTO privs ( userid, priv ) VALUES ( ?, ? )", userID, "all" )()
			end

			if ipAuth then
				chat.db.users( "INSERT INTO ipauths ( userid, ip ) VALUES ( ?, ? )", userID, ipAuth )()
			end

			if aliasPattern then
				chat.db.users( "INSERT INTO settings ( userid, setting, value ) VALUES ( ?, ?, ? )", userID, "alias", aliasPattern )()

				client.settings.alias = aliasPattern
			end
		end )

		client.userID = userID

		client:msg( "You're all set - happy trashtalking!" )
		client:replaceHandler( chatHandler )

		adminCode = nil
	end
end

local function registrationHandler( client )
	client:msg( "Cool. What do you want your #lwactual#d password to be?" )

	local password
	local createAccount = false

	while true do
		local command, args = coroutine.yield()

		if command == "all" then
			client:msg( "#lw%s %s <password>#d, not global chat!", client.pmSyntax, chat.config.name )
		end

		if command == "pm" then
			if args == "" then
				client:msg( "A blank password is not a good password." ) 
			else
				password = args
				createAccount = true

				break
			end
		end

		if command == "nameChange" then
			client:msg( "Don't do that..." )
			client:kill()

			break
		end
	end

	if createAccount then
		local salt = bcrypt.salt( chat.config.bcryptRounds )
		local digest = bcrypt.digest( password, salt )

		chat.db.users( "UPDATE users SET password = ?, isPending = 0 WHERE userID = ?", digest, client.userID )()

		client:msg( "You're all set - #lw%s#d me #lwhelp#d for exciting things.", client.pmSyntax )
		client:replaceHandler( chatHandler )

		adminCode = nil
	end
end

local function checkRegistrationHandler( client, password )
	client:msg( "Hey, #lw%s#d, you should have been given an #lwextremely secret#d password. #lw%s#d me that!", client.name, client.pmSyntax )

	while true do
		local command, args = coroutine.yield()

		if command == "all" then
			client:msg( "#lw%s %s <password>#d, not global chat!", client.pmSyntax, chat.config.name )
		end

		if command == "pm" then
			if bcrypt.verify( args, password ) then
				client:replaceHandler( registrationHandler )
			else
				client:msg( "Nope." )
				client:kill()
			end

			break
		end

		if command == "nameChange" then
			client:msg( "Don't do that..." )
			client:kill()

			break
		end
	end
end

local function initClientSettings( client )
	for setting, value in chat.db.users( "SELECT setting, value FROM settings WHERE userid = ?", client.userID ) do
		client.settings[ setting ] = value
	end

	for priv in chat.db.users( "SELECT priv FROM privs WHERE userid = ?", client.userID ) do
		client.privs[ priv ] = true
	end
end

local function authHandler( client )
	local lower = client.name:lower()

	local isPending, userID, password = chat.db.users( "SELECT isPending, userID, password FROM users WHERE name = ?", lower )()

	if isPending == 1 then
		client.userID = userID
		client:replaceHandler( checkRegistrationHandler, password )

		return
	end

	if userID then
		client.userID = userID

		local ok = false

		for ip, mask in chat.db.users( "SELECT ip, mask FROM ipauths WHERE userid = ?", client.userID ) do
			table.insert( client.ips, {
				ip = ip,
				mask = mask,
			} )

			if math.ipmask( ip, mask ) == math.ipmask( client.ip, mask ) then
				ok = true
			end
		end
		
		if ok then
			initClientSettings( client )

			client:msg( "Authed for #ly%s#ld...", client.ip )
			client:replaceHandler( chatHandler )

			return
		end
	end

	client:msg( "Hey, #lw%s#d! #lw%s#d me your password.", client.name, client.pmSyntax )

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			if userCount == 0 and args == adminCode then
				client.privs.all = true

				chat.db.users( function( db )
					db( "INSERT INTO users ( name ) VALUES ( ? )", client.name:lower() )()

					client.userID = db( "SELECT last_insert_rowid()" )()

					db( "INSERT INTO privs ( userid, priv ) VALUES ( ?, 'all' )", client.userID )()
				end )

				client:msg( "Setting up admin account..." )
				client:replaceHandler( registrationHandler )

				break
			end

			if not userID or not bcrypt.verify( args, password ) then
				client:msg( "Nope." )
				client:kill()
			else
				initClientSettings( client )

				client:replaceHandler( chatHandler )
			end

			break
		end

		if command == "nameChange" then
			client:nameChange( args )
		end
	end
end

local function checkTempAuth( client )
	local now = os.time()
	local lower = client.name:lower()

	for name, time in pairs( chat.tempAuths ) do
		if now > time then
			chat.tempAuths[ name ] = nil
		end
	end

	local ok = chat.tempAuths[ lower ] ~= nil
	chat.tempAuths[ lower ] = nil

	return ok
end

local function connectHandler( client )
	local data = coroutine.yield()
	local zchat, name = data:match( "^(Z?)CHAT:([%w%p]+)\t?%d*\n" )

	if not name then
		client:raw( "NO" )
		client:kill()

		log.error( "Couldn't find name in %s", input )

		return
	end

	local protocol = assert( Protocols[ zchat == "Z" and "zmud" or "mm" ] )

	setmetatable( client, {
		__index = protocol.client,
	} )

	client:setDataHandler( protocol.handler )

	client.name = name
	client.state = "connected"

	client:raw( "YES:" .. chat.config.name .. "\n" )

	table.insertBy( chat.clients, client, function( a, b )
		return a.name:lower() < b.name:lower()
	end )

	if chat.config.auth and not checkTempAuth( client ) then
		client:pushHandler( authHandler )
	else
		client:pushHandler( chatHandler )
	end
end

return {
	connect = connectHandler,
	chat = chatHandler,
}
