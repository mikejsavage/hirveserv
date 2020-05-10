local lfs = require( "lfs" )
local json = require( "cjson.safe" )

local lua53_or_higher = _VERSION ~= "Lua 5.1" and _VERSION ~= "Lua 5.2"

local websocket
if lua53_or_higher then
	log.info( "Using websockets" )
	websocket = require( "websocket" )
else
	log.info( "Upgrade to Lua 5.3 or higher to enable websockets" )
end

local modules = require( "modules" )

local ConnectionTimeout = 10

local _M = { }
local Client = { }

chat.clients = { }

chat.protocols = {
	require( "protocols.mm" )
}

for _, protocol in ipairs( chat.protocols ) do
	setmetatable( protocol.client, { __index = Client } )
end

function _M.new( socket )
	local client = {
		dataBuffer = "",

		socket = socket,
		state = "connecting",

		handlers = { },
	}

	chat.delay( ConnectionTimeout, function()
		if client.state == "connecting" then
			client.socket:shutdown()
		end
	end )

	setmetatable( client, { __index = Client } )

	return client
end

function Client:kill( msg )
	if msg then
		self:msg( msg )
	end

	if self.state == "chatting" then
		modules.fireEvent( "disconnect", self )
	end

	self.state = "killed"
	self.socket:shutdown()

	table.removeValue( chat.clients, self )

	if self.user then
		table.removeValue( self.user.clients, self )
	end
end

function Client:onData( data )
	if not self.websocket then
		self.dataBuffer = self.dataBuffer .. data
		self:processData()
	else
		self.websocket.buffer = self.websocket.buffer .. data

		while true do
			local frame, len = websocket.parse_frame( self.websocket.buffer )
			if not frame then
				break
			end

			local ok, data, response, expect_continuation = websocket.process_frame( frame, self.websocket.expect_continuation )

			if data then
				table.insert( self.websocket.frames, data )

				if not expect_continuation then
					self.dataBuffer = self.dataBuffer .. table.concat( self.websocket.frames, "" )
					self.websocket.frames = { }
					self:processData()
				end
			end

			if response then
				self.websocket:send( response )
			end

			if not ok then
				self:kill()
			end

			self.websocket.buffer = self.websocket.buffer:sub( len )
			self.websocket.expect_continuation = expect_continuation
		end
	end
end

function Client:processData()
	if lua53_or_higher and not self.websocket then
		local ok, len, response = websocket.handshake( self.dataBuffer )
		if ok then
			self.socket:send( response )

			local rest = self.dataBuffer:sub( len )
			self.websocket = {
				buffer = "",
				frames = { },
				expect_continuation = false,
			}
			self.dataBuffer = ""
			self:onData( rest )
		end
	end

	for _, protocol in ipairs( chat.protocols ) do
		if protocol.accept( self ) then
			setmetatable( self, { __index = protocol.client } )

			table.insertBy( chat.clients, self, function( other )
				return self.lower < other.lower
			end )

			self.state = "connected"

			if chat.config.auth then
				self:pushHandler( "auth" )
			else
				self:pushHandler( "chat" )
			end
		end
	end

	if self.state == "connecting" then
		if self.dataBuffer:len() > 1024 then
			self:kill()
		end
	end
end

function Client:raw( data )
	if not self.websocket then
		self.socket:send( data )
	else
		self.socket:send( websocket.binary( data ) )
	end
end

function Client:handler( command )
	for i = #self.handlers, 1, -1 do
		local handler = self.handlers[ i ]

		if handler.implements[ command ] then
			return handler.coro, handler.name
		end
	end
end

local function removeDeadHandlers( client )
	if client.state == "killed" then
		return
	end

	for i = #client.handlers, 1, -1 do
		if coroutine.status( client.handlers[ i ].coro ) == "dead" then
			table.remove( client.handlers, i )
		end
	end

	if #client.handlers == 0 then
		error( "%s ran out of coroutines" % client.name )
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
	local coro = coroutine.running()

	for i = #self.handlers, 1, -1 do
		if self.handlers[ i ].coro == coro then
			table.remove( self.handlers, i )

			break
		end
	end

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
	elseif command == "version" then
		self.version = args
	elseif command ~= "pingResponse" then
		local coro, name = self:handler( command )

		if coro then
			local ok, err = coroutine.resume( coro, command, args )

			if not ok then
				error( "client(%s) coro(%s) failed: %s" % { self.name, name, err } )
			end
		end

		removeDeadHandlers( self )
	end
end

function Client:msg( form, ... )
	enforce( form, "form", "string", "table" )

	local prompt = self.state == "chatting" and modules.prompt( self ) or ""

	if type( form ) == "table" then
		self:send( "message", chat.parseColours(
			"#lr<%s%s#lr>#lw %s" % { chat.config.name, prompt, table.concat( form, "\n" ) }
		) )
	else
		self:send( "message", chat.parseColours(
			"#lr<%s%s#lr>#lw %s" % { chat.config.name, prompt, form:format( ... ) }
		) )
	end
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
		local ok, err = chat.pcall( Client.pushHandler, self, "chat" )

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
