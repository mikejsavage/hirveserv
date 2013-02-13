local words = require( "include.words" )

chat.command( "adduser", "adduser", {
	[ "^(%S+)$" ] = function( client, name )
		local lower = name:lower()

		local userid, isPending = chat.db.users( "SELECT userid, isPending FROM users WHERE name = ?", lower )()

		local password = words.random()

		local salt = bcrypt.salt( chat.config.bcryptRounds )
		local digest = bcrypt.digest( password, salt )

		if isPending then
			chat.db.users( "UPDATE users SET password = ? WHERE userid = ?", digest, userid )()
		else
			chat.db.users( "INSERT INTO users ( name, password ) VALUES ( ?, ? )", lower, digest )()
		end

		client:msg( "Ok! Tell #ly%s#d their password is #ly%s#d.", name, password )
		chat.msg( "#ly%s#d added user #ly%s#d.", client.name, name )
	end,
}, "<name>", "Create a new user account" )

chat.command( "rempending", "adduser", {
	[ "^(.+)$" ] = function( client, name )
		local lower = name:lower()

		chat.db.users( "DELETE FROM pending WHERE name = ?", lower )()

		client:msg( "Ok." )
	end
}, "<name>", "Remove a pending account" )

chat.command( "password", "user", function( client, password )
	if password == "" then
		client:msg( "A blank password is not a good password." )

		return
	end

	local salt = bcrypt.salt( chat.config.bcryptRounds )
	local digest = bcrypt.digest( password, salt )

	chat.db.users( "UPDATE users SET password = ? WHERE userid = ?", digest, client.userID )()
	
	client:msg( "Your password has been updated!" )
end, "Change your password" )

chat.command( "addprivs", "privs", {
	[ "^(.-)%s+(.-)$" ] = function( client, name, privStr )
		local privs = { }
		local target = chat.clientFromName( name, true ) 

		if not target then
			client:msg( "There's nobody called #lw%s#d.", name )

			return
		end

		chat.db.users( function()
			for priv in privStr:gmatch( "([^,]+)" ) do
				if target.privs then
					if not target.privs[ priv ] then
						target.privs[ priv ] = true

						table.insert( privs, priv )
					end
				end

				chat.db.users( "INSERT INTO privs ( userid, priv ) VALUES ( ?, ? )", target.userID, priv )()
			end
		end )

		if target.state == "chatting" and #privs > 0 then
			target:msg( "You have been granted #lw%s#d privs.", table.concat( privs, "#d,#lw " ) )
		end

		client:msg( "Ok." )
	end,
}, "<name> <privs>", "Add privs to an account" )

chat.command( "remprivs", "privs", {
	[ "^(.-)%s+(.-)$" ] = function( client, name, privStr )
		local privs = { }
		local target = chat.clientFromName( name, true ) 

		if not target then
			client:msg( "There's nobody called #lw%s#d.", name )

			return
		end

		chat.db.users( function()
			for priv in privStr:gmatch( "([^,]+)" ) do
				if target.privs then
					if target.privs[ priv ] then
						target.privs[ priv ] = nil

						table.insert( privs, priv )
					end
				end

				chat.db.users( "DELETE FROM privs WHERE userid = ? AND priv = ?", target.userID, priv )()
			end
		end )

		if target.state == "chatting" and #privs > 0 then
			target:msg( "Your #lw%s#d privs have been revoked.", table.concat( privs, "#d,#lw " ) )
		end

		client:msg( "Ok." )
	end,
}, "<name> <privs>", "Remove privs from an account" )
