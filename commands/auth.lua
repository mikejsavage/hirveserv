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
}, "[name]", "Create a new user account" )

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
