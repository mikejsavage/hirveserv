Client = { }

local handlers = require( "include.handlers" )
local command = require( "include.command" )

chat.clients = { }

function Client:new( socket )
	socket:settimeout( 0 )
	socket:setoption( "keepalive", true )

	local client = {
		socket = socket,
		state = "connecting",
		dataHandler = coroutine.create( handlers.connect ),
		commandHandlers = { },
		privs = { },
		settings = { },
	}

	assert( coroutine.resume( client.dataHandler, client ) )

	setmetatable( client, { __index = Client } )

	return client
end

function Client:kill()
	self.socket:shutdown()

	if self.state == "chatting" then
		chat.event( "disconnect", self )

		self:xmsg( "#lw%s#d left chat.", self.name )
	end

	table.removeValue( chat.clients, self )
end

function Client:raw( data )
	self.socket:send( data )
end

function Client:send()
	error( "Client:send not implemented for protocol `%s'" % self.protocol )
end

function Client:msg()
	error( "Client:msg not implemented for protocol `%s'" % self.protocol )
end

function Client:chat()
	error( "Client:chat not implemented for protocol `%s'" % self.protocol )
end

function Client:handleCommand()
	error( "Client:handleCommand not implemented for protocol `%s'" % self.protocol )
end

function Client:ping()
	error( "Client:ping not implemented for protocol `%s'" % self.protocol )
end

function Client:pmSyntax()
	error( "Client:pmSyntax not implemented for protocol `%s'" % self.protocol )
end

function Client:hasPriv( priv )
	if priv == "user" then
		return self.userID ~= nil
	end

	return not priv or self.privs.all or self.privs[ priv ]
end

function Client:xmsg( form, ... )
	local message = form:format( ... )

	chat.event( "xmsg", self, message )

	for _, client in ipairs( chat.clients ) do
		if client ~= self and client.state == "chatting" then
			client:msg( message )
		end
	end
end

function Client:chatAll( message )
	chat.event( "chatAll", self, message )

	for _, client in ipairs( chat.clients ) do
		if client ~= self and client.state == "chatting" then
			client:chat( message )
		end
	end
end

function Client:pm( message )
	command.doCommand( self, message )
end

function Client:nameChange( newName )
	if self.state == "chatting" then
		chat.event( "nameChange", self, newName )

		self:xmsg( "#lw%s#d changed their name to #lw%s#d.", self.name, newName )
	end

	self.name = newName

	table.removeValue( chat.clients, self )
	table.insertBy( chat.clients, self, function( a, b )
		return a.name:lower() < b.name:lower()
	end )
end

function Client:setDataHandler( handler )
	self.dataHandler = coroutine.create( handler )

	assert( coroutine.resume( self.dataHandler, self ) )
end

function Client:pushHandler( handler, ... )
	local coro = coroutine.create( handler )

	table.insert( self.commandHandlers, coro )

	assert( coroutine.resume( coro, self, ... ) )
end

function Client:replaceHandler( handler, ... )
	table.remove( self.commandHandlers )

	self:pushHandler( handler, ... )
end

function Client:command( command, args )
	local coro = self.commandHandlers[ #self.commandHandlers ]

	assert( coroutine.resume( coro, command, args ) )

	-- can't test coro incase it calls Client:replaceHandler
	if coroutine.status( self.commandHandlers[ #self.commandHandlers ] ) == "dead" then
		table.remove( self.commandHandlers )
	end
end

function Client:data( data )
	assert( coroutine.resume( self.dataHandler, data ) )
end

function chat.msg( form, ... )
	local message = form:format( ... )

	chat.event( "msg", message )

	for _, client in ipairs( chat.clients ) do
		if  client.state == "chatting" then
			client:msg( message )
		end
	end
end

function chat.clientFromName( name, registered )
	name = name:lower()

	if registered then
		for _, client in ipairs( chat.clients ) do
			if client.name:lower() == name then
				return client
			end
		end

		local userID = chat.db.users( "SELECT userid FROM users WHERE name = ?", name )()

		if not userID then
			return nil, "not found"
		end

		return {
			name = name,
			userID = userID,
		}
	else
		local match

		for _, client in ipairs( chat.clients ) do
			if client.name:lower():startsWith( name ) then
				if match then
					return nil
				else
					match = client
				end
			end
		end
	end
end
