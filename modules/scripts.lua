local json = require( "cjson.safe" )

local sends = {
	"sendAction",
	"sendAlias",
	"sendMacro",
	"sendVariable",
	"sendEvent",
	"sendGag",
	"sendHighlight",
	"sendList",
	"sendArray",
	"sendBarItem",
}

local sendsPM = { "pm" }

for _, send in ipairs( sends ) do
	table.insert( sendsPM, send )
end

local scripts = { }
local scriptsMap = { }

local prompts = { }

local function validScript( script )
	return pcall( function()
		assert( type( script.author ) == "string" )
		assert( type( script.description ) == "string" )
		assert( not script.long or type( script.long ) == "string" )
		assert( type( script.updated ) == "number" )

		for _, line in ipairs( script.script ) do
			assert( table.find( sends, line.type ) )
			assert( type( line.line ) == "string" )
		end
	end )
end

local function loadScripts()
	for file in lfs.dir( "data/scripts" ) do
		local name = file:match( "^(.+)%.json$" )

		if not name then
			if file ~= "." and file ~= ".." then
				log.warn( "Stray file in data/scripts: %s", file )
			end
		else
			local script = json.decode( io.contents( "data/scripts/" .. file ) )

			if script and validScript( script ) then
				local lower = name:lower()

				script.name = name
				scriptsMap[ lower ] = script

				table.insertBy( scripts, script, function( other )
					return lower < other.name:lower()
				end )
			else
				log.warn( "Corrupt script: %s", name )
			end
		end
	end
end

local function saveScript( name )
	io.writeFile( "data/scripts/" .. name .. ".json", json.encode( scriptsMap[ name:lower() ] ) )
end

lfs.mkdir( "data/scripts" )

loadScripts()

local function listScripts( client )
	local msg = { "Available scripts:" }

	local installed = client.user.settings.scripts or { }

	for _, script in ipairs( scripts ) do
		local lower = script.name:lower()

		table.insert( msg, "#lm%-12s #lw- %s#lg%s#lr%s" % {
			script.name,
			script.description,
			installed[ lower ] and " [installed]" or "",
			installed[ lower ] and script.updated > installed[ lower ] and " [OUTDATED]" or "",
		} )
	end

	client:msg( msg )
end

local function scriptInfo( client, name )
	local script = scriptsMap[ name:lower() ]

	if not script then
		client:msg( "No such script!" )

		return
	end

	local msg = {
		"Script: #lm%s#lw:" % script.name,
		"#lwAuthor: #ly%s" % script.author,
		"#lwLast updated: #lg%s" % os.date( "%e %b", script.updated ),
	}

	if script.long then
		table.insert( msg, "\n#lw%s" % script.long )
	end

	client:msg( msg )
end

chat.handler( "addScript", sendsPM, function( client, name, description, callback )
	local lines = { }

	client:msg(
		"You need to send me your script. You can do it with #lm/send*#lw commands."
		.. "\nIf your script is all in a group, use #lm/sendgroup {%s} {<group>}"
		.. "\n#lm%s#lw me #lgdone#lw or #lgcancel#lw when you are done.",
		chat.config.name, client.pmSyntax
	)

	local lastOk

	while true do
		local command, args = coroutine.yield()

		if command == "pm" then
			if args == "done" then
				if #lines == 0 then
					client:msg( "Your script is still empty!" )
				else
					callback( lines )

					break
				end
			elseif args == "cancel" then
				client:msg( "Nevermind." )

				callback( nil )

				break
			else
				client:msg( "Valid commands are #lgdone#lw or #lgcancel#lw." )
			end
		else
			table.insert( lines, {
				type = command,
				line = args,
			} )

			local now = os.time()
			if not lastOk or now - lastOk >= 2 then
				lastOk = now

				client:msg( "Ok..." )
			end
		end
	end
end )

local function addScript( client, name, description )
	local lower = name:lower()
	local script = scriptsMap[ lower ]

	if not script and not description then
		client:msg( "You need a description eg: #lmaddscript %s This script is cool" % name )

		return
	end

	if script and script.author ~= client.user.name then
		client:msg( "You can't update scripts that aren't yours." )

		return
	end

	client:pushHandler( "addScript", name, description, function( lines )
		if not lines then
			return
		end

		client:msg(
			"We ask you to give a long description of your plugin."
			.. "\nThis can be used to go into more detail about functionality, or as a helpfile."
		)

		client:pushHandler( "editor", ( script and script.long ) or "", function( long )
			local added = "added"

			if not script then
				script = {
					name = name,
					author = client.user.name,
				}

				table.insertBy( scripts, script, function( other )
					return lower < other.name:lower()
				end )

				scriptsMap[ lower ] = script
			else
				prompts = { }
				added = "updated"
			end

			if description then
				script.description = description
			end

			script.updated = os.time()
			script.long = long
			script.script = lines

			saveScript( name )

			if client.user.settings.scripts and client.user.settings.scripts[ lower ] then
				client.user.settings.scripts[ lower ] = script.updated
			end

			chat.msg( "#ly%s#lw just %s a script: #lm%s", client.name, added, name )
		end )

	end )
end

local function deleteScript( client, name )
	local lower = name:lower()

	if not scriptsMap[ lower ] then
		client:msg( "No such script!" )

		return
	end

	assert( os.remove( "data/scripts/" .. name .. ".json" ) )

	table.removeValue( scripts, scriptsMap[ lower ] )
	scriptsMap[ lower ] = nil

	chat.msg( "#ly%s#lw deleted script #lm%s#lw." % client.name, name )
end

local function installScript( client, name )
	local script = scriptsMap[ name:lower() ]

	if not script then
		client:msg( "No such script!" )

		return
	end

	if not client.acceptCommands then
		client:msg( "You need to let me send you scripts: #lm/chatcommands %s", chat.config.name )

		return
	end

	for _, line in ipairs( script.script ) do
		client:send( line.type, line.line )
	end

	local user = client.user

	prompts[ user ] = nil

	if not user.settings.scripts then
		user.settings.scripts = { }
	end

	user.settings.scripts[ name:lower() ] = script.updated
	user:save()
end

chat.command( "scripts", "user", {
	[ "^$" ] = listScripts,
	[ "^(%S+)$" ] = scriptInfo,
}, "[script] [version]", "List and get info about available scripts" )

chat.command( "addscript", "addscript", {
	[ "^(%S+)$" ] = addScript,
	[ "^(%S+)%s+(.+)$" ] = addScript,
}, "<script> [description]", "Add a script" )

-- delscript bsrep
chat.command( "delscript", "all", {
	[ "^(%S+)$" ] = deleteScript,
}, "<script>", "Delete a script" )

-- install script
chat.command( "install", "user", {
	[ "^(%S+)$" ] = installScript,
}, "<script> [version]", "Install a script" )

chat.prompt( function( client )
	local user = client.user

	if user and not prompts[ user ] and user.settings.scripts then
		for name, time in pairs( user.settings.scripts ) do
			local script = scriptsMap[ name ]

			if not script or script.updated > time then
				prompts[ user ] = "#lg[SCRIPTS]"
			end
		end
	end

	return prompts[ user ]
end )
