local words = require( "include.words" )

chat.command( "adduser", "adduser", {
	[ "^(.+)$" ] = function( client, name )
		local lower = name:lower()

		local exists = chat.db.users( "SELECT 1 FROM users WHERE name = ?", lower )()

		if exists then
			client:msg( "#lw%s#d already has an account.", name )

			return
		end

		if chat.pendingUsers[ lower ] then
			chat.pendingUsers[ lower ].time = os.time()
		else
			local code = words.random()

			chat.pendingUsers[ lower ] = {
				time = os.time(),
				code = code,
			}
		end

		client:msg( "Ok! Tell #lw%s#d their password is #lw%s#d.", name, chat.pendingUsers[ lower ].code )
	end,
}, "<name>", "Create a new user account" )

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
