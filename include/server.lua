local cqueues = require( "cqueues" )
local socket = require( "cqueues.socket" )

local Client = require( "include.client" )
local modules = require( "include.modules" )

local function sendPings()
	local now = tostring( cqueues.monotime() )

	for _, client in ipairs( chat.clients ) do
		if client.state ~= "connecting" then
			client:send( "pingRequest", now )
		end
	end
end

local function startWSServer()
	local websocket = require( "websocket" ).server.ev

	local wsServer = websocket.listen( {
		port = chat.config.wsPort,

		protocols = {
			chat = function( ws )
				local client = Client.new( ws, true )

				ws:on_message( function( ws, message )
					local ok, err = pcall( client.onData, client, message )

					if not ok then
						log.error( "client.onData: %s", err )
						client:kill()
					end
				end )

				ws:on_close( function()
					if client.state == "chatting" then
						modules.fireEvent( "disconnect", client )
					end

					client:kill()
				end )

				-- this doesn't mute handshake errors because
				-- lua-websockets is great
				ws:on_error( function() end )
			end,
		}
	} )
end

chat.loop:wrap( function()
	local server = socket.listen( "0.0.0.0", chat.config.port )

	for con in server:clients() do
		local client = Client.new( con )

		chat.loop:wrap( function()
			while true do
				local data = con:read( -4096 )
				if not data then
					break
				end

				local ok, err = pcall( client.onData, client, data )
				if not ok then
					log.error( "client.onData: %s", err )
					break
				end
			end

			client:kill()

			if client.state == "chatting" then
				modules.fireEvent( "disconnect", client )
			end
		end )
	end
end)

chat.loop:wrap( function()
	while true do
		cqueues.sleep( 30 )
		sendPings()
	end
end )

if chat.config.wsPort then
	startWSServer()
end
