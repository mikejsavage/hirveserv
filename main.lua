#! /usr/bin/lua

local cqueues = require( "cqueues" )

-- cd into binary dir for convenience
local lfs = require( "lfs" )

local serverDir = arg[ 0 ]:match( "^(.-)/[^/]*$" )
if serverDir then
	lfs.chdir( serverDir )
end

-- init
chat = { }
chat.loop = cqueues.new()
chat.config = require( "include.config" )

require( "include.utils" )
log = require( "include.log" )

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

require( "include.server" )
require( "include.modules" ).load()

if chat.config.chroot or chat.config.runas then
	local setuid = require( "setuid" )

	if chat.config.chroot then
		local ok, err = setuid.chroot( ".", chat.config.runas or nil )

		if not ok then
			log.error( "Failed chroot: %s", err )

			return
		end
	elseif chat.config.runas then
		local ok, err = setuid.setuser( chat.config.runas )

		if not ok then
			log.error( "Failed setuser: %s", err )

			return
		end
	end
end

assert( chat.loop:loop() )
