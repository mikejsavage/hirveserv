local lfs = require( "lfs" )

local ev = require( "ev" )
local loop = ev.Loop.default

local json = require( "cjson.safe" )

local bcrypt = require( "bcrypt" )
local words = require( "include.words" )

lfs.mkdir( "data/users" )

local users = { }
local tempAuths = { }

-- temp auths garbage collection
ev.Timer.new( function()
	for name, time in pairs( tempAuths ) do
		if time > os.time() then
			tempAuths[ name ] = nil
		end
	end
end, 1, chat.config.tempAuthDuration * 2 )

local function saveUser( user )
	if not user then
		return
	end

	local file = assert( io.open( "data/users/%s.json" % user.name, "w" ) )

	local toSave = {
		password = user.password,
		pending = user.pending,
		settings = user.settings,
		privs = user.privs,
		ips = user.ips,
	}

	file:write( json.encode( toSave ) )
	file:close()
end

local function checkUser( name, decoded, err )
	if not decoded then
		log.warn( "Couldn't decode %s: %s", user, err )
		return nil
	end

	if not decoded.password then
		log.warn( "%s doesn't have a password, skipping", user )
		return nil
	end

	decoded.name = name
	decoded.settings = decoded.settings or { }
	decoded.privs = decoded.privs or { }
	decoded.ips = decoded.ips or { }
	decoded.clients = { }

	decoded.save = function( self )
		saveUser( self )
	end

	decoded.msg = function( self, msg, ... )
		for _, client in ipairs( self.clients ) do
			client:msg( msg, ... )
		end
	end

	return decoded
end

for file in lfs.dir( "data/users" ) do
	local user = file:match( "^(%l+)%.json$" )

	if user then
		local contents, err = io.contents( "data/users/" .. file )

		if contents then
			users[ user ] = checkUser( user, json.decode( contents ) )
		else
			log.warn( "Couldn't read user json: %s", err )
		end
	end
end

chat.command( "auth", "adduser", function( client, name )
	name = name:trim()

	if name == "" then
		client:msg( "Syntax: auth <name>" )

		return
	end

	tempAuths[ name:lower() ] = os.time() + chat.config.tempAuthDuration

	chat.msg( "#ly%s#lw is authing #ly%s#lw temporarily.", client.name, name )
end, "<name>", "Authenticate someone for %d second%s" % {
	chat.config.tempAuthDuration,
	string.plural( chat.config.tempAuthDuration )
} )

chat.command( "adduser", "adduser", {
	[ "^(%S+)$" ] = function( client, name )
		local lower = name:lower()

		if users[ lower ] and not users[ lower ].pending then
			client:msg( "#ly%s#lw already has an account!", name )

			return
		end

		local password = words.random()

		local salt = bcrypt.salt( chat.config.bcryptRounds )
		local digest = bcrypt.digest( password, salt )

		users[ lower ] = {
			password = digest,
			pending = true,
		}

		checkUser( lower, users[ lower ] )
		users[ lower ]:save()

		client:msg( "Ok! Tell #ly%s#lw their password is #lm%s#lw.", name, password )
		chat.msg( "#ly%s#lw added user #ly%s#lw.", client.name, lower )
	end,
}, "<account>", "Create a new user account" )

chat.command( "deluser", "accounts", function( client, name )
	local lower = name:lower()

	if not users[ lower ] then
		client:msg( "#ly%s#lw doesn't have an account.", name )

		return
	end

	local ok, err = os.remove( "data/users/%s.json" % lower )

	if not ok then
		error( "Couldn't delete user: %s" % err )
	end

	users[ lower ] = nil

	chat.msg( "#ly%s#lw deleted account #ly%s#lw.", client.name, lower )
end, "<account>", "Remove an account" )

chat.command( "reset", "accounts", function( client, name )
	local lower = name:lower()

	if not users[ lower ] then
		client:msg( "#ly%s#lw doesn't have an account.", name )

		return
	end

	local password = words.random()

	local salt = bcrypt.salt( chat.config.bcryptRounds )
	local digest = bcrypt.digest( password, salt )

	users[ lower ].password = digest
	users[ lower ].pending = true
	users[ lower ]:save()

	client:msg( "Ok! Tell #ly%s#lw their password is #lm%s#lw.", name, password )
end, "<account>", "Reset someone's password" )

chat.command( "setpw", "user", function( client, password )
	if password == "" then
		client:msg( "No empty passwords." )
		
		return
	end

	local salt = bcrypt.salt( chat.config.bcryptRounds )
	local digest = bcrypt.digest( password, salt )

	client.user.password = digest
	client.user:save()

	client:msg( "Your password has been updated." )
end, "<password>", "Change your password" )

chat.command( "whois", nil, function( client, name )
	local lower = name:lower()
	local other = users[ lower ]

	if not other then
		other = chat.clientFromName( lower )

		if not other then
			client:msg( "There's nobody called #ly%s#lw.", name )
			return
		end

		if not other.user then
			client:msg( "Whois #ly%s#lw: #lrUNAUTHENTICATED", other.name )
			return
		end

		other = other.user
	end

	local privs = "#lwprivs:#lm"
	for priv in pairs( other.privs ) do
		privs = privs .. " " .. priv
	end

	local clients = "#lwclients:"
	local alt = true
	for _, c in ipairs( other.clients ) do
		if c.state == "chatting" then
			clients = clients .. " " .. ( alt and "#ly" or "#lm" ) .. c.name
			alt = not alt
		end
	end

	client:msg( "Whois #ly%s#lw: %s %s", other.name, privs, clients )
end, "<account>", "Displays account info" )

chat.command( "addprivs", "accounts", {
	[ "^(%S+)%s+(.-)$" ] = function( client, name, privs )
		local other = users[ name:lower() ]

		if not other then
			client:msg( "There's nobody called #ly%s#lw.", name )
			return
		end

		local privList = { }
		local bad = { }

		for priv in privs:gmatch( "(%a+)" ) do
			other.privs[ priv ] = true
			table.insert( privList, priv )
		end

		other:save()

		local nice = "#lm" .. table.concat( privList, "#lw,#lm " )

		client:msg( "Gave #ly%s %s #lwprivs.", other.name, nice )
		other:msg( "You have been granted %s#lw privs.", nice )
	end,
}, "<account> <priv1> [priv2 ...]", "Grant a user privs" )

chat.command( "remprivs", "accounts", {
	[ "^(%S+)%s+(.-)$" ] = function( client, name, privs )
		local other = users[ name:lower() ]

		if not other then
			client:msg( "There's nobody called #ly%s#lw.", name )
			return
		end

		local privList = { }

		for priv in privs:gmatch( "(%a+)" ) do
			other.privs[ priv ] = nil
			table.insert( privList, priv )
		end

		other:save()

		local nice = "#lm" .. table.concat( privList, "#lw,#lm " )

		client:msg( "Revoked #ly%s#lw's %s #lwprivs.", other.name, nice )
		other:msg( "Your %s#lw privs have been revoked.", nice )
	end,
}, "<account> <priv1> [priv2 ...]", "Revoke a user's privs" )

chat.command( "lsip", "user", function( client )
	if #client.user.ips == 0 then
		client:msg( "You have no authed IPs." )

		return
	end

	local lines = { "Authed IPs:" }

	for _, ip in ipairs( client.user.ips ) do
		table.insert( lines, "#ly%s#lw: %s%s" % {
			ip.name,
			ip.ip,
			ip.prefix ~= 32 and ( "#lm/%d" % ip.prefix ) or ""
		} )
	end

	client:msg( lines )
end, "List authenticated IPs" )

local function iptoint( ip )
	local a, b, c, d = ip:match( "^(%d+)%.(%d+)%.(%d+)%.(%d+)$" )
	return d + 256 * ( c + 256 * ( b + 256 * a ) )
end

local function currentIPIndex( client )
	local addr = client.socket:getpeername()
	local n = iptoint( addr )

	for i, ip in ipairs( client.user.ips ) do
		local m = iptoint( ip.ip )
		local div = 2 ^ ( 32 - ip.prefix )

		if math.floor( m / div ) == math.floor( n / div ) then
			return i
		end
	end

	return nil
end

local function ipIndexFromName( client, name )
	for i, ip in ipairs( client.user.ips ) do
		if ip.name == name then
			return i
		end
	end

	return nil
end

local function addIP( client, name, prefix )
	local idx = ipIndexFromName( client, name )
	if idx then
		client:msg( "You are already authed from #ly%s#lw.", name )

		return
	end

	local currIdx = currentIPIndex( client )
	if currIdx then
		local authed = client.user.ips[ currIdx ]

		client:msg( "IP #ly%s#lw (#ly%s#lm/%d#lw) already covers your current address.",
			authed.name, authed.ip, authed.prefix )

		return
	end

	local ip = client.socket:getpeername()

	table.insert( client.user.ips, {
		name = name,
		ip = ip,
		prefix = prefix,
	} )
	table.sortByKey( client.user.ips, "name" )
	client.user:save()

	client:msg( "Added #ly%s#lw (#ly%s#lm/%d#lw) as an authenticated IP.", name, ip, prefix )
end

chat.command( "addip", "user", {
	[ "^(%S+)$" ] = function( client, name )
		addIP( client, name, 32 )
	end,

	[ "^(%S+)%s+(%d+)$" ] = addIP,
}, "<where you are connecting from> [network prefix]", "Add an authenticated IP" )

chat.command( "delip", "user", function( client, args )
	local idx

	if args == "" then
		idx = currentIPIndex( client )

		if not idx then
			client:msg( "You aren't authenticated from this IP. Use #lylsip#lw for a list." )

			return
		end
	else
		idx = ipIndexFromName( client, args )

		if not idx then
			client:msg( "You aren't authenticated from #lm%s#lw. Use #lylsip#lw for a list.", args )
			
			return
		end
	end

	local name = client.user.ips[ idx ].name

	table.remove( client.user.ips, idx )
	client.user:save()

	client:msg( "Removed #ly%s#lw from authenticated IPs.", name )
end, "[name]", "Remove an authenticated IP" )
		

chat.handler( "register", { "pm" }, function( client )
	client:msg( "Hey, #ly%s#lw, you should have been given an #lmextremely secret#lw password. #ly/chat#lw me that!", client.name )

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			if bcrypt.verify( args, client.user.password ) then
				break
			end

			return client:kill( "Nope." )
		end
	end

	while true do
		client:msg( "What do you want your #lmactual#lw password to be?" )

		local command, args = coroutine.yield()

		if command == "pm" then
			if args == "" then
				client:msg( "No empty passwords." )
			else
				local salt = bcrypt.salt( chat.config.bcryptRounds )
				local digest = bcrypt.digest( args, salt )

				client.user.password = digest
				client.user.pending = nil
				client.user:save()

				break
			end
		end
	end

	client:replaceHandler( "chat" )
end )

chat.handler( "auth", { "pm" }, function( client )
	local lower = client.name:lower()

	client.user = users[ client.name:lower() ]

	if not client.user then
		if tempAuths[ lower ] and os.time() < tempAuths[ lower ] then
			tempAuths[ lower ] = nil
			return client:replaceHandler( "chat" )
		end

		return client:kill( "You don't have an account." )
	end

	table.insert( client.user.clients, client )

	if client.user.pending then
		return client:replaceHandler( "register" )
	end

	if currentIPIndex( client ) then
		return client:replaceHandler( "chat" )
	end

	client:msg( "Hey, #ly%s#lw! #lm/chat#lw me your password.", client.name )

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			if bcrypt.verify( args, client.user.password ) then
				return client:replaceHandler( "chat" )
			end

			return client:kill( "Nope." )
		end
	end
end )

local makeFirstAccount = chat.config.auth and pairs( users ) == nil

if makeFirstAccount then
	io.stdout:write( "Let's make an account! What do you want the username to be? " )
	io.stdout:flush()

	local name
	while true do
		name = io.stdin:read( "*l" ):lower()

		if not name:match( "^%S+$" ) then
			print( "Name can't contain any whitespace!" )
		else
			break
		end
	end

	local password = words.random()

	local salt = bcrypt.salt( chat.config.bcryptRounds )
	local digest = bcrypt.digest( password, salt )

	users[ name ] = {
		password = digest,
		pending = true,
		privs = { all = true },
	}

	checkUser( name, users[ name ] )
	users[ name ]:save()

	print( "Ok! %s's password is %s." % { name, password } )
end
