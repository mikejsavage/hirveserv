local ev = require( "ev" )
local loop = ev.Loop.default

local lfs = require( "lfs" )
local json = require( "cjson.safe" )

local modules = require( "include.modules" )

local ConnectionTimeoutLength = 10

local _M = { }
local Client = { }

chat.clients = { }

chat.protocols = {
	require( "protocols.mm" )
}

for _, protocol in ipairs( chat.protocols ) do
	setmetatable( protocol.client, { __index = Client } )
end

local function connectionTimeout( client )
	return function( loop, timer )
		client.socket:shutdown()
		timer:stop( loop )
	end
end

function _M.new( socket )
	socket:settimeout( 0 )
	socket:setoption( "keepalive", true )

	local client = {
		dataBuffer = "",

		socket = socket,
		state = "connecting",

		handlers = { },
	}

	client.timerConnection = ev.Timer.new( connectionTimeout( client ), ConnectionTimeoutLength, 0 )
	client.timerConnection:start( loop )

	setmetatable( client, { __index = Client } )

	return client
end

function Client:kill( msg )
	if msg then
		self:msg( msg )
	end

	self.state = "killed"
	self.socket:shutdown()

	table.removeValue( chat.clients, self )

	if self.user then
		table.removeValue( self.user.clients, self )
	end
end

function Client:onData( data )
	self.dataBuffer = self.dataBuffer .. data

	self:processData()
end

function Client:processData()
	for _, protocol in ipairs( chat.protocols ) do
		if protocol.accept( self ) then
			setmetatable( self, { __index = protocol.client } )

			table.insertBy( chat.clients, self, function( other )
				return self.lower < other.lower
			end )

			self.state = "connected"

			self.timerConnection:stop( loop )
			self.timerConnection = nil

			if chat.config.auth then
				self:pushHandler( "auth" )
			else
				self:pushHandler( "chat" )
			end
		end
	end
end

function Client:raw( data )
	self.socket:send( data )
end

function Client:handler( command )
	for i = #self.handlers, 1, -1 do
		local handler = self.handlers[ i ]

		if handler.implements[ command ] then
			return handler.coro, handler.name
		end
	end

	error( "%s has no handler for %s" % { self.name, command } )
end

function Client:removeDeadHandlers()
	if self.state == "killed" then
		return
	end

	for i = #self.handlers, 1, -1 do
		if coroutine.status( self.handlers[ i ].coro ) == "dead" then
			table.remove( self.handlers, i )
		end
	end
end

function Client:pushHandler( name, ... )
	local handler = modules.getHandler( name )
	local coro = coroutine.create( handler.coro )

	table.insert( self.handlers, {
		name = name,
		coro = coro,
		implements = handler.implements,
	} )

	local ok, err = coroutine.resume( coro, self, ... )
	if not ok then
		error( "failed coro(%s) initialisation: %s" % { name, err } )
	end
end

function Client:replaceHandler( name, ... )
	table.remove( self.handlers )

	self:pushHandler( name, ... )
end

function Client:hasPriv( priv )
	if not priv then
		return true
	end

	if not self.user then
		return false
	end

	return priv == "user" or self.user.privs.all or self.user.privs[ priv ]
end

function Client:onCommand( command, args )
	if command == "pingRequest" then
		self:send( "pingResponse", args )
	elseif command ~= "pingResponse" then
		local coro, name = self:handler( command )
		local ok, err = coroutine.resume( coro, command, args )

		if not ok then
			error( "client coro(%s) failed: %s" % { name, err } )
		end

		self:removeDeadHandlers()
	end
end

function Client:msg( form, ... )
	enforce( form, "form", "string", "table" )

	if type( form ) == "table" then
		form = table.concat( form, "\n" )
	end

	self:send( "message", chat.parseColours(
		"<%s>#lw %s" % { chat.config.name, form:format( ... ) }
	) )
end

function Client:xmsg( form, ... )
	local str = form:format( ... )

	modules.fireEvent( "msg", str )

	for _, client in ipairs( chat.clients ) do
		if ( ( client.user and client.user ~= self.user ) or client ~= self ) and client.state == "chatting" then
			client:msg( "%s", str )
		end
	end
end

function chat.msg( form, ... )
	local str = form:format( ... )

	modules.fireEvent( "msg", str )

	for _, client in ipairs( chat.clients ) do
		if client.state == "chatting" then
			client:msg( "%s", str )
		end
	end
end

-- TODO: not happy with this
function Client:hop()
	local oldCoros = self.coros
	self.coros = { }

	if self.state == "chatting" then
		local ok, err = pcall( Client.pushHandler, self, "chat" )

		if not ok then
			log.error( "hop failed for %s (state %s): %s", self.name, self.state, err )

			self.coros = oldCoros

			return false
		end
	end

	return true
end

function chat.clientFromName( name )
	name = name:lower()

	for _, client in ipairs( chat.clients ) do
		if client.state == "chatting" and client.name:lower() == name then
			return client
		end
	end

	return nil
end

return _M
