local Commands = { }
local CommandNames = { }

local function doCommand( client, message )
	message = message or ""

	local name, args = message:match( "^%s*(%S+)%s*(.*)$" )
	local command = Commands[ name ]

	if command and client:hasPriv( command.priv ) then
		local badSyntax = true

		for _, callback in ipairs( command.callbacks ) do
			local _, subs = args:gsub( callback.pattern, function( ... )
				callback.callback( client, ... )
			end )

			if subs ~= 0 then
				badSyntax = false

				break
			end
		end

		if badSyntax then
			client:msg( "syntax: %s %s", name, command.syntax )
		end
	else
		client:msg( "Huh? Use the #lwhelp#d command if you're stuck." )
	end
end

local function simpleCommand( priv, callback, help, longHelp )
	enforce( help, "help", "string" )

	return {
		priv = priv,

		callbacks = {
			{
				pattern = "^(.*)$",
				callback = callback
			},
		},

		help = help,
		longHelp = longHelp,
	}
end

local function patternCommand( priv, callbacks, syntax, help, longHelp )
	enforce( callbacks, "callbacks", "table" )
	enforce( syntax, "syntax", "string" )
	enforce( help, "help", "string" )

	local command = {
		callbacks = { },
		syntax = syntax,

		priv = priv,

		help = help,
		longHelp = longHelp,
	}

	for pattern, callback in pairs( callbacks ) do
		table.insert( command.callbacks, {
			pattern = pattern,
			callback = callback,
		} )
	end

	return command
end

function chat.command( name, priv, handler, ... )
	enforce( name, "name", "string" )
	enforce( priv, "priv", "string", "nil" )
	enforce( handler, "handler", "function", "string", "table" )

	assert( not Commands[ name ], "command `%s' already registered" % name )

	local command = type( handler ) == "function"
		and simpleCommand( priv, handler, ... )
		or patternCommand( priv, handler, ... )

	Commands[ name ] = command
	table.insert( CommandNames, name )
end

chat.command( "help", nil, {
	[ "^$" ] = function( client )
		local lines = {
			"Commands: (use #lwhelp <command>#d for detailed help)",
		}

		local maxCommandLen = 0

		for _, name in ipairs( CommandNames ) do
			if client:hasPriv( Commands[ name ].priv ) then
				maxCommandLen = math.max( name:len(), maxCommandLen )
			end
		end

		for _, name in ipairs( CommandNames ) do
			local command = Commands[ name ]

			if client:hasPriv( command.priv ) then
				table.insert( lines, ( "#lw%-" .. maxCommandLen .. "s#d - %s" ) % { name, command.help } )
			end
		end

		client:msg( lines )
	end,

	[ "^(.+)$" ] = function( client, name )
		local command = Commands[ name ]

		if not command then
			client:msg( "What is #lw%s#d?", name )

			return
		end

		if not command.longHelp then
			client:msg( "I don't have any more info on #lw%s#d, sorry.", name )

			return
		end

		client:msg( "Help for #lw%s#d:\n%s", name, command.longHelp )
	end,
}, "[command]", "This" )

require( "commands.auth" )
require( "commands.roll" )
require( "commands.who" )
require( "commands.log" )

return {
	doCommand = doCommand,
}
