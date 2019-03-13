local ev = require( "ev" )
local socket = require( "socket" )

local Client = require( "client" )
local modules = require( "modules" )

local PingInterval = 30

local function sendPings()
	local now = tostring( chat.now() )

	for _, client in ipairs( chat.clients ) do
		if client.state ~= "connecting" then
			client:send( "pingRequest", now )
		end
	end
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
	socket:setoption( "tcp-nodelay", true )

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
