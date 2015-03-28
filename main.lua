#! /usr/bin/lua

local ev = require( "ev" )
local loop = ev.Loop.default

-- cd into binary dir for convenience
local lfs = require( "lfs" )

local serverDir = arg[ 0 ]:match( "^(.-)/[^/]*$" )
if serverDir then
	lfs.chdir( serverDir )
end

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

-- init
chat = { }

require( "include.sigint" )
require( "include.utils" )
log = require( "include.log" )

chat.config = require( "include.config" )

local server = require( "include.server" )
local modules = require( "include.modules" )

server.init()
modules.load()

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

loop:loop()
