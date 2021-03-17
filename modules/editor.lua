local help = "#lmA#lwdd#d <text>             - add <text> to the end\n"
	.. "#lmS#lwave#d                   - save message and exit\n"
	.. "#lmI#lwnsert#d <line##> <text>  - insert a line\n"
	.. "#lmR#lweplace#d <line##> <text> - replace a line\n"
	.. "#lmD#lwelete#d <line##>         - delete a line\n"
	.. "#lmP#lwreview#d                - see what it looks like now\n"
	.. "#lmW#lwipe#d                   - wipe it clean\n"
	.. "#lwe#lmX#lwit#d                   - exit the editor without saving"

local shortHelp = "#lmA#lwdd #lmS#lwave #lmI#lwnsert #lmR#lweplace #lmD#lwelete #lmP#lwreview #lmW#lwipe e#lmX#lwit"

local shortCommands = {
	a = "add",
	s = "save",
	i = "insert",
	r = "replace",
	d = "delete",
	p = "preview",
	w = "wipe",
	x = "exit",
}

local validCommands = { }

for _, command in pairs( shortCommands ) do
	validCommands[ command ] = true
end

local function expandCommand( command )
	if not command then
		return nil
	end

	command = command:lower()

	if shortCommands[ command ] then
		return shortCommands[ command ]
	end

	return validCommands[ command ] and command
end

chat.handler( "editor", { "pm" }, function( client, initorcb, callback )
	local lines = { }
	local first = true

	if callback then
		for line in ( initorcb .. "\n" ):gmatch( "([^\n]*)\n" ) do
			table.insert( lines, line )
		end
	else
		callback = initorcb
	end

	client:msg( "Editing...\n"
		.. "You can #lm%s#lw me the following commands:\n"
		.. "(#lm!cmd#lw syntax also works if you have #lyalias#lw set up)\n"
		.. help, client.pmSyntax )

	while true do
		if not first then
			client:msg( "%s", shortHelp )
		end

		first = false

		local command, args = coroutine.yield()
		local editCommand, editArgs = args:match( "^(%S+)%s*(.-)$" )

		local real = expandCommand( editCommand )

		if not real then
			client:msg( "Huh?" )
		else
			if real == "save" then
				callback( table.concat( lines, "\n" ) )

				break
			elseif real == "preview" then
				if #lines == 0 then
					client:msg( "You haven't written anything." )
				else
					local numbered = { }

					for i, line in ipairs( lines ) do
						numbered[ i ] = "#lw%2d.#d %s" % { i, line }
					end

					client:msg( "Your message:\n%s", table.concat( numbered, "\n" ) )
				end
			elseif real == "wipe" then
				lines = { }

				client:msg( "Wiped." )
			elseif real == "exit" then
				client:msg( "Nevermind." )
				callback()

				break
			elseif real == "add" then
				table.insert( lines, editArgs )
			else
				local line, text = editArgs:match( "^(%d+)%s*(.-)$" )
				line = tonumber( line )

				if not line then
					client:msg( "Syntax: <line> [text]" )
				elseif real == "insert" then
					table.insert( lines, line, text )
				elseif real == "replace" then
					if not lines[ line ] then
						client:msg( "Bad line index." )
					else
						lines[ line ] = text
					end
				elseif real == "delete" then
					if not lines[ line ] then
						client:msg( "Bad line index." )
					else
						table.remove( lines, line )
					end
				end
			end
		end
	end
end )
