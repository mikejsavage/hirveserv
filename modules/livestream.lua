local streams = { }
local snooping = { }

chat.handler( "snoop", { "snoopData" }, function( client )
	while true do
		local command, args = coroutine.yield()
		assert( command == "snoopData" )

		if streams[ client.user.name ] then
			local data = args:match( "%d+\n(.*)$" )
			if not data then
				data = args
			end
			data = ( chat.parseColours( "#lg[" .. client.user.name:upper() .. "] " ) .. data ):trim()

			if data ~= "" then
				for _, snooper in ipairs( streams[ client.user.name ].snoopers ) do
					snooper:send( "message", data )
				end
			end
		end
	end
end )

-- TODO: this needs to push on reload too
chat.listen( "connect", function( client )
	client:pushHandler( "snoop" )
end )

local function stopStream( name )
	for _, snooper in ipairs( streams[ name ].snoopers ) do
		snooping[ snooper ] = nil
		snooper:msg( "#ly%s#lw killed their stream.", name )
	end

	streams[ name ] = nil
end

chat.listen( "disconnect", function( client )
	if client.user and streams[ client.user.name ] and streams[ client.user.name ].client == client then
		stopStream( client.user.name )
	end
end )

chat.command( "livestream", "user", function( client )
	local name = client.user.name

	if streams[ name ] then
		stopStream( name )
		client:msg( "Stopped streaming." )
		return
	end

	if client.allowSnoop then
		streams[ name ] = {
			client = client,
			snoopers = { },
		}
		client:send( "snoopStart" )

		chat.msg( "#ly%s#lw has started livestreaming! #lmsnoop %s#lw to watch them get CPKed!", name, name )
	else
		client:msg( "You need to #lm/chatsnoop#lw me!" )
	end
end, "Start/stop streaming" )

chat.command( "snoop", "user", {
	[ "^$" ] = function( client )
		local response = "Live streams:"

		local none = true
		local alt = true
		for streamer in pairs( streams ) do
			response = response .. " " .. ( alt and "#lm" or "#ly" ) .. streamer
			alt = not alt
			none = false
		end

		if none then
			response = response .. " nobody :("
		end

		if snooping[ client ] then
			response = response .. "\nYou are snooping #ly" .. snooping[ client ] .. "#lw."
		end

		client:msg( response )
	end,

	[ "^(%S+)$" ] = function( client, stream )
		if streams[ client.user.name ] then
			client:msg( "You can't snoop and stream at the same time." )
			return
		end

		if snooping[ client ] then
			client:msg( "Stopped snooping #ly%s#lw.", snooping[ client ] )
			table.removeValue( streams[ snooping[ client ] ].snoopers, client )
			snooping[ client ] = nil
		end

		stream = stream:lower()

		if not streams[ stream ] then
			client:msg( "#ly%s#lw isn't streaming.", stream )
			return
		end

		table.insert( streams[ stream ].snoopers, client )
		snooping[ client ] = stream

		client:msg( "Snooping #ly%s#lw! #lm%s#lw me #lmunsnoop#lw to stop snooping.", client.pmSyntax, stream )
	end,
}, "Watch a livestream" )

chat.command( "unsnoop", "user", function( client )
	if not snooping[ client ] then
		client:msg( "You're not snooping anyone!\n" )
		return
	end

	client:msg( "Stopped snooping #ly%s#lw.", snooping[ client ] )

	table.removeValue( streams[ snooping[ client ] ], client )
	snooping[ client ] = nil
end, "Stop watching livestreams" )

chat.prompt( function( client )
	if client.user and streams[ client.user.name ] then
		return "#lg[STREAMING]"
	end
end )
