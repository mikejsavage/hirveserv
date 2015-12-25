local lfs = require( "lfs" )

local _M = { }

local commands = { }
local commandNames = { }
local handlers = { }
local events = { }
local prompts = { }

local function meta( t )
	return {
		__index = t,
		__newindex = t,
	}
end

local function makeCallbacks( handler )
	if type( handler ) == "function" then
		return { {
			pattern = "^(.*)$",
			callback = handler,
		} }
	end

	local callbacks = { }

	for pattern, callback in pairs( handler ) do
		table.insert( callbacks, {
			pattern = pattern,
			callback = callback,
		} )
	end

	return callbacks
end

local function addCommand( newCommands, newCommandNames, name, priv, handler, syntax, description )
	enforce( name, "name", "string" )
	enforce( priv, "priv", "string", "nil" )
	enforce( handler, "handler", "function", "table" )
	enforce( syntax, "syntax", "string" )
	enforce( description, "description", "string", "nil" )

	assert( not newCommands[ name ], "already a command called " .. name )

	local callbacks = makeCallbacks( handler )

	newCommands[ name ] = {
		priv = priv,
		callbacks = callbacks,
		syntax = syntax,
		description = description or syntax,
	}
	table.insert( newCommandNames, name )
end

local function addHandler( newHandlers, name, implements, handler )
	enforce( name, "name", "string" )
	enforce( implements, "implements", "table" )
	enforce( handler, "handler", "function" )

	local impl = { }
	for _, command in ipairs( implements ) do
		impl[ command ] = true
	end

	assert( not newHandlers[ name ], "already a handler called " .. name )

	newHandlers[ name ] = {
		coro = handler,
		implements = impl,
	}
end

local function addListener( newEvents, name, callback )
	enforce( name, "name", "string" )
	enforce( callback, "callback", "function" )

	if not newEvents[ name ] then
		newEvents[ name ] = { }
	end

	table.insert( newEvents[ name ], callback )
end

local function addPrompt( newPrompts, callback )
	enforce( callback, "callback", "function" )

	table.insert( newPrompts, callback )
end

local function loadModule( path, newCommands, newCommandNames, newHandlers, newEvents, newPrompts )
	log.info( "Loading module: " .. path )

	local envchat = {
		command = function( name, priv, handler, syntax, description )
			addCommand( newCommands, newCommandNames, name, priv, handler, syntax, description )
		end,

		handler = function( name, implements, handler )
			addHandler( newHandlers, name, implements, handler )
		end,

		listen = function( name, callback )
			addListener( newEvents, name, callback )
		end,

		prompt = function( callback )
			addPrompt( newPrompts, callback )
		end,

		event = _M.fireEvent,
	}

	setmetatable( envchat, meta( chat ) )

	local env = setmetatable( { chat = envchat }, meta( _G ) )
	local fn = assert( loadfile( path, "t", env ) )

	if _VERSION == "Lua 5.1" then
		setfenv( fn, env )
	end

	assert( pcall( fn ) )
end

local function makeHelp( newCommands, newCommandNames )
	assert( not newCommands.help, "help command already exists" )

	addCommand( newCommands, newCommandNames, "help", nil, function( client )
		local lines = { "Commands:" }

		local maxCommandLen = 0
		for _, name in ipairs( newCommandNames ) do
			if client:hasPriv( newCommands[ name ].priv ) then
				maxCommandLen = math.max( name:len(), maxCommandLen )
			end
		end

		for _, name in ipairs( newCommandNames ) do
			local command = newCommands[ name ]

			if client:hasPriv( command.priv ) then
				table.insert( lines, ( "#ly%-" .. maxCommandLen .. "s #lw- %s" ) % {
					name, command.description
				} )
			end
		end

		client:msg( table.concat( lines, "\n" ) )
	end, "This" )
end

function _M.load()
	local newCommands = { }
	local newCommandNames = { }
	local newHandlers = { }
	local newEvents = { }
	local newPrompts = { }

	for module in lfs.dir( chat.config.dataDir .. "/modules" ) do
		if module:match( "%.lua$" ) then
			loadModule( chat.config.dataDir .. "/modules/" .. module,
				newCommands, newCommandNames, newHandlers,
				newEvents, newPrompts )
		end
	end

	makeHelp( newCommands, newCommandNames )

	commands = newCommands
	commandNames = newCommandNames
	handlers = newHandlers
	events = newEvents
	prompts = newPrompts

	log.info( "Done." )
end

function _M.getCommand( name )
	return commands[ name ]
end

function _M.getHandler( name )
	return handlers[ name ]
end

function _M.prompt( client )
	local prompt = ""

	for _, callback in ipairs( prompts ) do
		prompt = prompt .. ( callback( client ) or "" )
	end

	return prompt
end

function _M.fireEvent( name, ... )
	enforce( name, "name", "string" )

	if events[ name ] then
		for _, callback in ipairs( events[ name ] ) do
			callback( ... )
		end
	end
end

return _M
