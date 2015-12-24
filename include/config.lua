local config = setmetatable( {
	name = "hirveserv",
	port = 4050,
	auth = false,
	bcryptRounds = 5,
	tempAuthDuration = 60,
	chroot = false,
	runas = false,
	logLines = 2500,
	whatsit = false,
}, { __index = { } } )

local fn, err = loadfile( "config.lua", "t", config )
if not fn then
	log.error( "reading config.lua failed: %s", err )
	os.exit( 1 )
end

if _VERSION == "Lua 5.1" then
	setfenv( fn, config )
end

local ok, err_run = pcall( fn )
if not ok then
	log.error( "reading config.lua failed: %s", err )
	os.exit( 1 )
end

return config
