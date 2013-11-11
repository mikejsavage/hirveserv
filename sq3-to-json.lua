#! /usr/bin/lua

require( "lsqlite3" )
local json = require( "cjson.safe" )

local function newDB( file )
	local db = sqlite3.open( file )
	local statementCache = { }

	getmetatable( db ).__call = function( self, query, ... )
		if not statementCache[ query ] then
			statementCache[ query ] = assert( ( self:prepare( query ) ), self:errmsg() )
		end

		local statement = statementCache[ query ]

		statement:reset()

		if ... then
			statement:bind_values( ... )
		end

		local iter = statement:urows()

		return function()
			return iter( statement )
		end
	end

	return db
end

local function iptoint( ip )
	local a, b, c, d = ip:match( "^(%d+)%.(%d+)%.(%d+)%.(%d+)$" )
	return d + 256 * ( c + 256 * ( b + 256 * a ) )
end

local file = io.open( "data/users.version", "r" )
if not file or not file:read( "*all" ) == "5" then
	print( "You need to run the latest pre-rewrite version of hirveserv before you can cnovert your database." )
	print( "See https://github.com/mikejsavage/hirveserv" )
	os.exit()
end
file:close()

local users = { }
local db = newDB( "data/users.sq3" )

for userid, name, password, pending in db( "SELECT userid, name, password, isPending FROM users" ) do
	users[ userid ] = {
		name = name:lower(),
		password = password,
		pending = pending == 1 or nil,
		privs = { },
		settings = { },
		ips = { },
	}
end

for userid, priv in db( "SELECT userid, priv FROM privs" ) do
	users[ userid ].privs[ priv ] = true
end

for userid, setting, value in db( "SELECT userid, setting, value FROM settings" ) do
	users[ userid ].settings[ setting ] = value
end

for userid, ip, mask in db( "SELECT userid, ip, mask FROM ipauths" ) do
	local num = iptoint( mask )
	local log2 = 0

	while num % 2 == 0 do
		num = num / 2
		log2 = log2 + 1
	end

	local ok = true
	while num > 1 and ok do
		num = num - 1
		ok = ok and num % 2 == 0
		num = num / 2
	end

	if ok then
		table.insert( users[ userid ].ips, {
			name = tostring( #users[ userid ].ips ),
			ip = ip,
			prefix = 32 - log2,
		} )
	end
end

for _, user in pairs( users ) do
	local name = user.name
	user.name = nil

	print( name, json.encode( user ) )

	local file = io.open( "data/users/" .. name .. ".json", "w" )
	file:write( json.encode( user ) )
	file:close()
end
