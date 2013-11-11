#! /usr/bin/lua

require( "picky" )

local ev = require( "ev" )
local loop = ev.Loop.default

-- cd into binary dir for convenience
local lfs = require( "lfs" )

local serverDir = arg[ 0 ]:match( "^(.-)/[^/]*$" )
if serverDir then
	lfs.chdir( serverDir )
end

lfs.mkdir( "data" )
math.randomseed( os.time() )

-- init
chat = { }

require( "include.sigint" )
require( "include.utils" )
log = require( "include.log" )

chat.config = require( "include.defaults" )

local configFn, errLoad = loadfile( "config.lua" )
if configFn then
	local env = setmetatable( { }, {
		__newindex = function( self, key, value )
			if chat.config[ key ] == nil then
				log.warn( "invalid setting: %s", key )
			end

			chat.config[ key ] = value
		end,

		__index = { },
	} )

	setfenv( configFn, env )

	local ok, errRun = pcall( configFn )

	if not ok then
		log.error( "reading config.lua failed: %s", err )

		os.exit( 1 )
	end
else
	log.warn( "couldn't read config: %s", errLoad )
end

local server = require( "include.server" )
local modules = require( "include.modules" )

server.init()
modules.load()

loop:loop()
