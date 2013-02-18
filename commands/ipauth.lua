chat.command( "addip", "user", {
	[ "^$" ] = function( client )
		if client:ipIndex( client.ip ) then
			client:msg( "You are already authed for #ly%s#d!", client.ip )

			return
		end

		chat.db.users( "INSERT INTO ipauths ( userid, ip ) VALUES ( ?, ? )", client.userID, client.ip )()
		table.insert( client.ips, {
			ip = client.ip,
			mask = "255.255.255.255",
		} )

		client:msg( "Ok, added #ly%s#d as an authed IP.", client.ip )
	end,

	[ "^(%d+.%d+.%d+.%d+)$" ] = function( client, mask )
		if client:ipIndex( client.ip ) then
			client:msg( "You are already authed for #ly%s#d!", client.ip )

			return
		end

		chat.db.users( "INSERT INTO ipauths ( userid, ip, mask ) VALUES ( ?, ?, ? )", client.userID, client.ip, mask )()
		table.insert( client.ips, {
			ip = client.ip,
			mask = mask,
		} )

		client:msg( "Ok, added #ly%s#d as an authed IP.", client.ip )
	end,
}, "[mask]", "Add an authenticated IP with optional subnet mask" )

chat.command( "lsip", "user", function( client )
	local output = "Authed IPs:"

	for i, ip in ipairs( client.ips ) do
		output = output .. "\n#ly%d#d: #lw%s #dmask %s" % { i, ip.ip, ip.mask }
	end

	client:msg( output )
end, "List authenticated IPs" )

chat.command( "delip", "user", {
	[ "^(%d*)$" ] = function( client, idx )
		if idx == "" then
			idx = client:ipIndex( client.ip )

			if not idx then
				client:msg( "You're not authed for #ly%s#d. Use #lylsip#d for a list!", client.ip )

				return
			end
		else
			idx = tonumber( idx )

			if not client.ips[ idx ] then
				client:msg( "Bad IP index. Use #lylsip#d for a list!" )

				return
			end
		end

		local ip = client.ips[ idx ]

		chat.db.users( "DELETE FROM ipauths WHERE userID = ? AND ip = ? AND mask = ?", client.userID, ip.ip, ip.mask )()

		client:msg( "Ok, removed #ly%s#d as an authed IP.", ip.ip )

		table.remove( client.ips, idx )
	end,
}, "[idx]", "Delete an authenticated IP" )
