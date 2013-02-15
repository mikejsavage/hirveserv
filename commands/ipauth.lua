chat.command( "addip", "user", function( client )
	if client:ipIndex( client.ip ) then
		client:msg( "You are already authed for #ly%s#d!", client.ip )

		return
	end

	chat.db.users( "INSERT INTO ipauths ( userid, ip ) VALUES ( ?, ? )", client.userID, client.ip )()
	table.insert( client.ips, client.ip )

	client:msg( "Ok, added #ly%s#d as an authed IP.", client.ip )
end, "Add an authenticated IP" )

chat.command( "lsip", "user", function( client )
	local output = "Authed IPs:"

	for i, ip in ipairs( client.ips ) do
		output = output .. "\n#ly%d#d: #lw%s" % { i, ip }
	end

	client:msg( output )
end, "List authenticated IPs" )

chat.command( "delip", "user", function( client, args )
	local idx = tonumber( args )

	if idx then
		if not client.ips[ idx ] then
			client:msg( "Bad IP index. Use #lylsip#d for a list!" )

			return
		end
	else
		if args:match( "^%d+%.%d+%.%d+%.%d+$" ) then
			idx = client:ipIndex( ip )
		end

		if not idx then
			client:msg( "That IP isn't authed for you. Use #lylsip#d for a list!" )

			return
		end
	end

	chat.db.users( "DELETE FROM ipauths WHERE userID = ? AND ip = ?", client.userID, client.ips[ idx ] )()

	client:msg( "Ok, removed #ly%s#d as an authed IP.", client.ips[ idx ] )

	table.remove( client.ips, idx )
end, "Delete an authenticated IP" )
