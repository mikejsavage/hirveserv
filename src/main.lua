local ev = require( "ev" )

-- cd into binary dir for convenience
local lfs = require( "lfs" )

local serverDir = arg[ 0 ]:match( "^(.-)/[^/]*$" )
if serverDir then
	lfs.chdir( serverDir )
end

-- init
chat = { }
chat.loop = ev.Loop.default

require( "sigint" )
require( "utils" )
log = require( "log" )

chat.config = require( "config" ).load( arg[ 1 ] )

lfs.mkdir( "data" )

-- use arc4random if it's installed
local ok, arc4 = pcall( require, "arc4random" )
if ok then
	log.info( "Using arc4random" )
	math.random = arc4.random
else
	-- TODO: seed from urandom?
	math.randomseed( os.time() )
end

require( "server" )
require( "modules" ).load()

chat.loop:loop()
