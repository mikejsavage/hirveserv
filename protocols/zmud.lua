local CommandBytes = {
	nameChange = string.ushort( 1 ),
	all = string.ushort( 4 ),
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

local function dataHandler( client )
	while true do
		local data = coroutine.yield()

		local commandByte, args = data:match( "^(..)......(.*)$" )
		local command = Commands[ commandByte ]

		if command == "pm" then
			client:command( "pm", args:match( "chats to you[:,] '(.*)'\n$" ) )
		elseif command == "pingRequest" then
			client:send( "pingResponse", args )
		elseif command == "stamp" then
			self.stamp = arg:sub( 1, -2 ) .. string.char( ( arg:byte( -1 ) +  1 ) % 256 )
		elseif command and command ~= "pingResponse" then
			client:command( command, args )
		end
	end
end

local ZMudClient = setmetatable( {
	protocol = "zmud",
	stamp = string.uint( 0 ),
}, { __index = Client } )

function ZMudClient:send( command, data )
	local byte = CommandBytes[ command ]

	assert( byte, "bad command: " .. command )

	self:raw( byte .. string.ushort( data:len() ) .. data )
end

function ZMudClient:msg( form, ... )
	enforce( form, "form", "string", "table" )

	if type( form ) == "table" then
		form = table.concat( form, "\n" )
	end

	self:send( "message", chat.parseColours( "%s<%s>#d %s" % { self.stamp, chat.config.name, form:format( ... ) } ) )
end

function ZMudClient:chat( message )
	enforce( message, "message", "string" )

	self:send( "all", self.stamp .. message )
end

function ZMudClient:ping( now )
	self:send( "pingRequest", now )
end

return {
	client = ZMudClient,
	handler = dataHandler,
}
