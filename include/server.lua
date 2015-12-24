local ev = require( "ev" )
local socket = require( "socket" )

local Client = require( "include.client" )
local modules = require( "include.modules" )

local PingInterval = 30

local function sendPings()
	local now = tostring( chat.now() )

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
					client:kill()
				end )

				-- this doesn't mute handshake errors because
				-- lua-websockets is great
				ws:on_error( function() end )
			end,
		}
	} )
end

server = assert( socket.bind( "*", chat.config.port ) )
server:settimeout( 0 )
server:setoption( "keepalive", true )

local function onData( client )
	return function( loop, watcher )
		-- lol
		local _, err, data = client.socket:receive( "*a" )

		if err == "closed" then
			watcher:stop( loop )
			client:kill()

			return
		end

		if not data then
			data = _
		end

		if data then
			local ok, errData = pcall( client.onData, client, data )

			if not ok then
				log.error( "client.onData: %s", errData )
				client:kill()
			end
		else
			log.error( "data == nil: %s", err )
		end
	end
end

local function onConnection()
	local socket, err = server:accept()
	if not socket then
		log.warn( "server:accept failed: %s", err )
		return
	end

	socket:settimeout( 0 )
	socket:setoption( "keepalive", true )

	local client = Client.new( socket )

	ev.IO.new(
		onData( client ),
		socket:getfd(),
		ev.READ
	):start( chat.loop )
end

ev.IO.new(
	onConnection,
	server:getfd(),
	ev.READ
):start( chat.loop )

chat.every( PingInterval, sendPings )

if chat.config.wsPort then
	startWSServer()
end
