local CommandBytes = {
	nameChange = string.ushort( 1 ),
	chat = string.ushort( 4 ),
	pm = string.ushort( 5 ),
	message = string.ushort( 7 ),
	pingRequest = string.ushort( 26 ),
	pingResponse = string.ushort( 27 ),
	stamp = string.ushort( 106 ),
}

local Commands = { }

for name, byte in pairs( CommandBytes ) do
	Commands[ byte ] = name
end

local ZMudClient = {
	protocol = "zmud",
	pmSyntax = "##chat",
	stamp = string.uint( 0 ),
}

function ZMud:processData()
	while true do
		local bytes, len1, len2 = self.dataBuffer:match( "^(..)(.)(.)" )

		if not bytes then
			break
		end

		local len = string.byte( len1 ) + string.byte( len2 ) * 256

		if self.dataBuffer:len() >= len + 4 then
			local command = Commands[ bytes ]
			local args = self.dataBuffer:sub( 5, len + 4 )

			if command == "chat" then
				self:onCommand( "chat", args:sub( 5 ) )
			elseif command == "pm" then
				self:onCommand( "pm", args:match( "chats to you[:,] '(.*)'\n$" ):trimVT102() )
			elseif command == "stamp" then
				self.stamp = arg:sub( 1, -2 ) .. string.char( ( arg:byte( -1 ) + 1 ) % 256 )
			elseif command then
				self:onCommand( command, args )
			end

			self.dataBuffer = self.dataBuffer:sub( len + 5 )
		end
	end
end

function ZMudClient:send( command, data )
	enforce( command, "command", "string" )
	enforce( args, "args", "string" )

	local bytes = CommandBytes[ command ]

	assert( byte, "bad command: " .. command )

	if command == "chat" or command == "message" then
		data = self.stamp .. data
	end

	self:raw( bytes .. string.ushort( data:len() ) .. data )
end

local _M = { client = ZMudClient }

function _M.accept( client )
	-- if SecurityInfo splits across multiple packets or "optional data"
	-- gets sent we are fucked...
	local name, len = client.dataBuffer:match( "ZCHAT:(.-)\t[^\n]*\n[^\n]*\n.+()" )

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
