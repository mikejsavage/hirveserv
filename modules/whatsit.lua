if not chat.config.whatsit then
	return
end

local cqueues = require( "cqueues" )
local socket = require( "cqueues.socket" )

local json = require( "cjson.safe" )

local addr = "/tmp/whatsit_%s.sock" % chat.config.whatsit
local whatsit

local recentMessages = { }
local claims = { }

local function whatsappMessage( number, message )
	whatsit:write( json.encode( {
		action = "message",
		to = number .. "@s.whatsapp.net",
		body = message,
	} ) .. "\n" )
end

local function whatsappBroadcast( numbers, message )
	for i, number in ipairs( numbers ) do
		whatsappMessage( number, message )
		-- numbers[ i ] = number .. "@s.whatsapp.net"
	end

	-- whatsit:write( json.encode( {
	-- 	action = "broadcast",
	-- 	to = numbers,
	-- 	body = message,
	-- } ) .. "\n" )
end

local function numberToUser( phone )
	for _, user in pairs( chat.users ) do
		if user.settings.whatsapp == phone then
			return user
		end
	end

	return nil
end

chat.command( "whatsapp", "user", {
	[ "^$" ] = function( client )
		if client.user.settings.whatsapp then
			client:msg( "Your saved phone number is: #ly%s#lw. Use #lmwhatsapp forget#lw to stop receiving messages.", client.user.settings.whatsapp )
		elseif claims[ client.user ] then
			client:msg( "#ly%s#lw is claiming they're you. Use #lmwhatsapp confirm#lw if that's true.", claims[ client.user ] )
		else
			client:msg( "Message #ly%s#lw to #lm%s#lw to register.", client.user.name, chat.config.whatsit )
		end
	end,

	[ "^confirm$" ] = function( client )
		if not claims[ client.user ] then
			client:msg( "You need to send #lm%s#lw (your username) to #ly%s#lw first.", client.user.name, user.settings.whatsapp )
			return
		end

		client.user.settings.whatsapp = claims[ client.user ]
		client.user:save()
		claims[ client.user ] = nil

		client:msg( "Ok!" )
	end,

	[ "^forget$" ] = function( client )
		client.user.settings.whatsapp = nil
		client.user:save()

		client:msg( "Ok!" )
	end,
}, "", "View and modify WhatsApp settings" )

chat.listen( "chat", function( _, message )
	local trimmed = message:stripVT102():trim()
	table.insert( recentMessages, trimmed )

	if #recentMessages > 5 then
		table.remove( recentMessages, 1 )
	end

	if trimmed:lower():match( "analprobe" ) then
		local recent = table.concat( recentMessages, "\n" )
		local numbers = { }

		for _, user in pairs( chat.users ) do
			if user.settings.whatsapp then
				table.insert( numbers, user.settings.whatsapp )
			end
		end

		whatsappBroadcast( numbers, recent )
	end
end )

chat.loop:wrap( function()
	while true do
		whatsit = socket.connect( { path = addr } )

		pcall( function()
			for line in whatsit:lines( "*l" ) do
				local message, err = json.decode( line )
				if message then
					local number = message.from:match( "^(%d+)" )
					local user = numberToUser( number )

					if user then
						print( "%s says %s" % { user.name, message.body } )
					else
						local name = message.body:lower()
						for _, client in ipairs( chat.clients ) do
							if client.user and client.user.name == name then
								client:msg( "#ly%s#lw is claiming they're you. Use #lmwhatsapp confirm#lw if that's true.", number )

								claims[ client.user ] = number
								break
							end
						end
					end
				else
					log.warn( "Bad message: " .. message )
				end
			end
		end )

		cqueues.sleep( 5 )
	end
end )
