local CommandBytes = {
	nameChange = "\1",
	all = "\4",
	pm = "\5",
	message = "\7",
	pingRequest = "\26",
	pingResponse = "\27",
}

local Commands = { }

for name, byte in pairs( CommandBytes ) do
	Commands[ byte ] = name
end

local MMClient = {
	protocol = "mm",
	pmSyntax = "/chat",
}

function MMClient:processData()
	local byte, args, len = self.dataBuffer:match( "^(.)(.*)\255()" )

	if byte then
		local command = Commands[ byte ]

		if command == "pm" then
			local pm = args:match( "chats to you, '(.*)'\n$" )
			
			if pm then
				self:onCommand( "pm", pm:trimVT102() )
			end
		elseif command then
			self:onCommand( command, args )
		end

		self.dataBuffer = self.dataBuffer:sub( len )
	end
end

function MMClient:send( command, args )
	enforce( command, "command", "string" )
	enforce( args, "args", "string" )

	local byte = CommandBytes[ command ]

	assert( byte, "bad command: " .. command )

	self:raw( byte .. args .. "\255" )
end

local _M = { client = MMClient }

function _M.accept( client )
	local name, len = client.dataBuffer:match( "^CHAT:(.-)\n.+[%d ][%d ][%d ][%d ][%d ]()" )

	if not name then
		return false
	end

	client.name = name
	client.lower = name:lower()
	client.dataBuffer = client.dataBuffer:sub( len )

	client:raw( "YES:" .. chat.config.name .. "\n" )

	return true
end

return _M
