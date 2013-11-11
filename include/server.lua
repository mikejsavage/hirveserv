local ev = require( "ev" )
local socket = require( "socket" )

local Client = require( "include.client" )

local _M = { }

local loop = ev.Loop.default
local server

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
	-- TODO: error
	local client = Client.new( server:accept() )

	ev.IO.new(
		onData( client ),
		client.socket:getfd(),
		ev.READ
	):start( loop )
end

local function sendPings()
	local now = tostring( loop:update_now() )

	for _, client in ipairs( chat.clients ) do
		if client.state ~= "connecting" then
			client:send( "pingRequest", now )
		end
	end
end

function _M.init()
	server = assert( socket.bind( "*", chat.config.port ) )

	server:settimeout( 0 )
	server:setoption( "keepalive", true )

	ev.IO.new(
		onConnection,
		server:getfd(),
		ev.READ
	):start( loop )

	ev.Timer.new( sendPings, 30, 30 ):start( loop )
end

return _M
