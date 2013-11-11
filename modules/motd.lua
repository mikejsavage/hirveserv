local motd = io.contents( "data/motd.txt" )

local function sendMotd( client )
	if motd and motd ~= "" then
		client:msg( "%s", motd )
	end
end

chat.command( "motd", nil, sendMotd, "Show message of the day" )

chat.command( "setmotd", "user", function( client, args )
	if args == "" then
		client:msg( "Blank MOTD = boring." )
		return
	end

	local newMotd = args:gsub( "\\n", "\n" )

	local file = assert( io.open( "data/motd.txt", "w" ) )
	file:write( newMotd )
	file:close()

	motd = newMotd

	chat.msg( "#ly%s#lw sounds the MOTD alarm! %s", client.name, newMotd )
end, "Update MOTD" )

chat.listen( "connect", sendMotd )
