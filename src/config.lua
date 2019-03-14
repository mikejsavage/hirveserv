local _M = { }

function _M.load( path )
	path = path or "/etc/hirveserv.conf"

	local config = setmetatable( {
		name = "hirveserv",
		debug = false,
		port = 4050,
		auth = false,
		bcryptRounds = 5,
		tempAuthDuration = 60,
		logLines = 2500,
		dataDir = "/var/lib/hirveserv",
		whatsit = false,
	}, { __index = { } } )

	local fn, err = loadfile( path, "t", config )
	if not fn then
		log.error( "reading config failed: %s", err )
		os.exit( 1 )
	end

	if _VERSION == "Lua 5.1" then
		setfenv( fn, config )
	end

	local ok, err_run = pcall( fn )
	if not ok then
		log.error( "reading config failed: %s", err )
		os.exit( 1 )
	end

	return config
end

return _M
