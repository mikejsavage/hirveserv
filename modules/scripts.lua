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
	for file in lfs.dir( chat.config.dataDir .. "/scripts" ) do
		local name = file:match( "^(.+)%.json$" )

		if not name then
			if file ~= "." and file ~= ".." then
				log.warn( "Stray file in data/scripts: %s", file )
			end
		else
			local script = json.decode( io.contents( chat.config.dataDir .. "/scripts/" .. file ) )

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
	io.writeFile( "%s/scripts/%s.json" % { chat.config.dataDir, name },
		json.encode( scriptsMap[ name:lower() ] ) )
end

lfs.mkdir( chat.config.dataDir .. "/scripts" )

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
		"#lwLast updated: #lg%s" % os.date( "%e %b %y", script.updated ),
	}

	if script.long then
		table.insert( msg, "\n#lw%s" % script.long )
	end

	table.insert( msg, "\n#lm/chat {%s} install %s#lw to install and be notified of updates." % {
		chat.config.name, script.name
	} )

	client:msg( msg )
end

local function isMMRecent( version )
	local major, minor = version:match( "^MudMaster 2k6 - ([%d.]+) Build (%d+)$" )

	if not major then
		return false
	end

	local fmajor = tonumber( major )
	minor = tonumber( minor )

	return fmajor > 4.28 or ( major == "4.28" and build >= 18 )
end

chat.handler( "addScript", sendsPM, function( client, name, description, callback )
	local lines = { }

	local bugged = not isMMRecent( client.version )

	client:msg(
		"You need to send me your script. You can do it with #lm/send*#lw commands."
		.. "\nIf your script is all in a group, use #lm/sendgroup {%s} {<group>}"
		.. "\n#lm/chat {%s} done/cancel#lw when you are done."
		, chat.config.name, chat.config.name
	)

	if bugged then
		client:msg(
			"#lrNote that to work around a MM bug you will need to #lm/chat {%s} events#lw before sending events."
			.. "\nYou can also download a fixed version from #lchttp://sourceforge.net/projects/mm2k6/files/mm2k6/MudMaster%%202k6%%20v4.2.8/"
			, chat.config.name
		)
	end

	local lastAnything
	local lastEvent

	local acceptEvents = not bugged

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
			elseif args == "events" and bugged then
				acceptEvents = not acceptEvents

				client:msg( "Ok,%s accepting events." % { acceptEvents and "" or " no longer" } )
			else
				client:msg( "Valid commands are #lgdone#lw or #lgcancel#lw." )
			end
		else
			local now = chat.now()

			if command == "sendEvent" and not acceptEvents then
				if not lastEvent or now - lastEvent >= 0.4 then
					client:msg(
						"If you want to send events, you need to #lm/chatt#lw me #lgevents#lw."
						.. "\nThis is to work around a MM bug."
					)
				end

				lastEvent = now
			else
				if command == "sendVariable" then
					args = args:gsub( "/variable{", "/variable {" )
				end

				table.insert( lines, {
					type = command,
					line = args,
				} )
			end

			if not lastAnything or now - lastAnything >= 0.4 then
				client:msg( "Ok..." )
			end

			lastAnything = now
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

	assert( os.remove( "%s/scripts/%s.json" % { chat.config.dataDir, name } ) )

	table.removeValue( scripts, scriptsMap[ lower ] )
	scriptsMap[ lower ] = nil

	chat.msg( "#ly%s#lw deleted script #lm%s#lw.", client.name, name )
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
