#! /usr/bin/lua

chat = { }

local lfs = require( "lfs" )

local serverDir = arg[ 0 ]:match( "^(.-)/[^/]*$" )

if serverDir then
	lfs.chdir( serverDir )
end

lfs.mkdir( "data" )

require( "picky" )
require( "config" )

math.randomseed( os.time() )

require( "include.utils" )
require( "include.event" )
require( "include.sqlite" )

local schema = require( "include.schema" )

chat.db = {
	users = sqlite.new( "data/users.sq3" ),
	logs = sqlite.new( "data/logs.sq3" ),
}

schema.users( chat.db.users )
schema.logs( chat.db.logs )

require( "include.client" )

local addons = require( "include.addons" )

local socket = require( "socket" )
local ev = require( "ev" )

local loop = ev.Loop.default
local server = assert( socket.bind( "*", chat.config.port ) )

server:settimeout( 0 )
server:setoption( "keepalive", true )

local function dataHandler( client, loop, watcher )
	-- this makes perfect sense
	local _, err, data = client.socket:receive( "*a" )

	if err == "closed" then
		watcher:stop( loop )
		client:kill()

		return
	end

	client:data( data )
end

local function connectHandler()
	local client = Client:new( server:accept() )

	ev.IO.new(
		function( loop, watcher )
			dataHandler( client, loop, watcher )
		end,

		client.socket:getfd(),
		ev.READ
	):start( loop )
end

local function sendPings()
	local now = loop:update_now()

	for _, client in ipairs( chat.clients ) do
		if client.state ~= "connecting" then
			client:ping( now )
		end
	end
end

addons.load()

ev.IO.new( connectHandler, server:getfd(), ev.READ ):start( loop )
ev.Timer.new( sendPings, 30, 30 ):start( loop )

loop:loop()
