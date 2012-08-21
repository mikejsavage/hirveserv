local CommandBytes = {
	nameChange = "\1",
	all = "\4",
	pm = "\5",
	pingRequest = "\26",
	pingResponse = "\27",
}

local Commands = { }

for name, byte in pairs( CommandBytes ) do
	Commands[ byte ] = name
end

local function dataHandler( client )
	while true do
		local data = coroutine.yield()

		local commandByte, args = data:match( "^(.)(.*)\255$" )
		local command = Commands[ commandByte ]

		if command == "pm" then
			client:command( "pm", args:match( "chats to you, '(.*)'\n$" ) )
		elseif command == "pingRequest" then
			client:send( "pingResponse", args )
		elseif command then
			client:command( command, args )
		end
	end
end

local MMClient = setmetatable( { protocol = "mm" }, { __index = Client } )

function MMClient:send( command, data )
	local byte = CommandBytes[ command ]

	assert( byte, "bad command: " .. command )

	self:raw( byte .. chat.parseColours( data ) .. "\255" )
end

function MMClient:msg( form, ... )
	enforce( form, "form", "string", "table" )

	if type( form ) == "table" then
		form = table.concat( form, "\n" )
	end

	self:send( "pm", "<%s>#d %s" % { chat.config.name, form:format( ... ) } )
end

function MMClient:chat( message )
	enforce( message, "message", "string" )

	self:send( "all", message )
end

return {
	client = MMClient,
	handler = dataHandler,
}
