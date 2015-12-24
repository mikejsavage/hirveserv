local json = require( "cjson" )

local white = json.decode( io.contents( "data/cah/white.json" ) )
local black = json.decode( io.contents( "data/cah/black.json" ) )

local MINPLAYERS = 4
local HANDSIZE = 10

-- To start the game, each player draws ten white "answer" cards. One randomly
-- chosen player begins as the Card Czar, and plays a black "question" card.
-- The Card Czar reads the question out to the group. Each player answers the
-- question by passing one white "answer" card, face down, to the Card Czar.
-- The Card Czar shuffles all of the answers, reads them out loud in a humorous
-- fashion, and picks their favorite. Whoever played that answer gets to keep
-- the Black Card as one Awesome Point.  After each round, a new player becomes
-- the Card Czar, and every player draws back up to ten cards.[9]

local function loadGame()
	local state = io.contents( "data/cah/state.json" )
	local default = {
		state = "answers",

		questions = table.random( #black ),
		scores = { },

		decks = { },
		hands = { },
		answers = { },
		votes = { },
	}

	return state and json.decode( state ) or default
end

local game = loadGame()
game.start = os.time()

local function niceTimeToNext( toofew )
	if #table.keys( game[ game.state ] ) < MINPLAYERS then
		return "#lrwhen more players have " .. ( game.state == "answers" and "answered" or "voted" )
	end

	local elapsed = os.time() - game.start
	local remains = 15 * 60 - elapsed

	if remains < 360 then
		return "#lgin a few minutes"
	end

	return "#lyin %d minutes" % math.floor( remains / 60 )
end

local function drawCards( name )
	while #game.hands[ name ] < HANDSIZE do
		table.insert( game.hands[ name ], game.decks[ name ][ 1 ] )
		table.remove( game.decks[ name ], 1 )
	end
end

local function giveClientCards( name )
	if not game.decks[ name ] then
		game.decks[ name ] = table.random( #white )
		game.hands[ name ] = { }
		drawCards( name )
	end
end

local function getNiceQuestion( name )
	if not name then
		return black[ game.questions[ 1 ] ].text:gsub( "%%s", "#lr__________#lw" )
	end

	local card = black[ game.questions[ 1 ] ]

	if not card.text:find( "%%s" ) then
		local result = { black[ game.questions[ 1 ] ].text .. "#lr" }

		for _, id in ipairs( game.answers[ name ] ) do
			table.insert( result, white[ game.hands[ name ][ id ] ] )
		end

		return table.concat( result, " " )
	end

	local cards = { }

	for _, id in ipairs( game.answers[ name ] ) do
		table.insert( cards, "#lr" .. white[ game.hands[ name ][ id ] ] .. "#lw" )
	end

	return black[ game.questions[ 1 ] ].text % cards
end

local function statusAnswering( client )
	local name = client.user.name

	giveClientCards( name )

	local msg = {
		getNiceQuestion( game.answers[ name ] and name ),
		"#lgANSWERING: #lwVoting begins %s#lw. Your hand:" % niceTimeToNext(),
	}

	for i, id in ipairs( game.hands[ name ] ) do
		table.insert( msg, "#lm%2d: #lw%s" % { i, white[ game.hands[ name ][ i ] ] } )
	end

	table.insert( msg, "#lycards answer #lgcard1 card2 ... #lwto answer" )

	client:msg( "%s", table.concat( msg, "\n" ) )
end

local function statusVoting( client )
	local name = client.user.name

	local msg = {
		getNiceQuestion(),
		"#lcVOTING: #lwThe next round will begin %s#lw." % niceTimeToNext(),
	}

	for i, answer in ipairs( game.answersList ) do
		local color = game.votes[ name ] == answer.name and "#lr" or "#lm"

		table.insert( msg, "%s%2d: #lw%s" % { color, i, getNiceQuestion( answer.name ) } )
	end

	table.insert( msg, "#lycards vote #lganswer #lwto %svote" % { game.votes[ name ] and "change your " or "" } )

	client:msg( "%s", table.concat( msg, "\n" ) )
end

local function cmdStatus( client )
	if game.state == "answers" then
		statusAnswering( client )
	elseif game.state == "votes" then
		statusVoting( client )
	end
end

local function cmdAnswer( client, args )
	if game.state ~= "answers" then
		client:msg( "You can't answer now!" )

		return
	end

	local name = client.user.name
	local ids = { }
	local used = { }

	giveClientCards( name )

	for id in args:gmatch( "(%d+)" ) do
		id = tonumber( id )

		if id < 1 or id > HANDSIZE then
			client:msg( "Bad card: #lm%d", id )

			return
		end

		if used[ id ] then
			client:msg( "You can't use cards twice!" )

			return
		end

		table.insert( ids, id )
		used[ id ] = true
	end

	if #ids ~= black[ game.questions[ 1 ] ].blanks then
		client:msg( "This question needs #lm%d#lw answers.", black[ game.questions[ 1 ] ].blanks )

		return
	end

	table.sort( ids )

	game.answers[ name ] = ids

	client:msg( "Answered with: %s", getNiceQuestion( name ) )

	if #table.keys( game.answers ) == MINPLAYERS then
		game.start = os.time()

		chat.msg( "#lmCards Against Humanity: #lwvoting begins in #lg15 minutes#lw!" )
	end
end

local function cmdVote( client, args )
	if game.state ~= "votes" then
		client:msg( "You can't vote now!" )

		return
	end

	local name = client.user.name
	local id = tonumber( args )

	if id < 1 or id > #game.answersList then
		client:msg( "Bad answer." )

		return
	end

	if game.answersList[ id ].name == name then
		client:msg( "don't be a nerd" )

		return
	end

	game.votes[ name ] = game.answersList[ id ].name

	client:msg( "Voted for: %s", getNiceQuestion( game.votes[ name ] ) )

	if #table.keys( game.votes ) == MINPLAYERS then
		game.start = os.time()

		chat.msg( "#lmCards Against Humanity: #lwvoting ends in #lg15 minutes#lw!" )
	end
end

local function cmdTop( client )
end

chat.command( "cards", "user", {
	[ "^$" ] = cmdStatus,
	[ "^answer%s+([%d%s]+)$" ] = cmdAnswer,
	[ "^vote%s+(%d+)$" ] = cmdVote,
	[ "^top$" ] = cmdTop,
	[ "^history$" ] = cmdHistory,
}, "answer <ids>/vote <id>/top/history", "Cards Against Humanity" )

local function advanceGame()
	if os.time() - game.start < ( 60 * 15 ) or #table.keys( game[ game.state ] ) < MINPLAYERS then
		return
	end

	if game.state == "answers" then
		game.state = "votes"
		game.answersList = { }

		for name, answer in pairs( game.answers ) do
			table.insert( game.answersList, {
				ids = answer,
				name = name,
			} )
		end

		table.shuffle( game.answersList )

		chat.msg( "#lmCards Against Humanity: #lwtime's up, get voting!" )
	elseif game.state == "votes" then
		game.state = "answers"

		local tally = { }
		for _, name in pairs( game.votes ) do
			tally[ name ] = ( tally[ name ] or 0 ) + 1
		end

		for _, answer in ipairs( game.answersList ) do
			answer.votes = tally[ answer.name ] or 0
		end

		table.sortByKey( game.answersList, "votes", true )

		local winners = 0
		for _, answer in ipairs( game.answersList ) do
			if answer.votes == game.answersList[ 1 ].votes then
				winners = winners + 1
			else
				break
			end
		end

		local winner = game.answersList[ math.random( winners ) ]
		game.scores[ winner.name ] = ( game.scores[ winner.name ] or 0 ) + 1

		chat.msg( "#lmCards Against Humanity: #lwtime's up, #ly%s#lw wins!\n%s", winner.name, getNiceQuestion( winner.name ) )

		for _, answer in ipairs( game.answersList ) do
			local name = answer.name

			for i = #answer.ids, 1, -1 do
				table.insert( game.decks[ name ], game.hands[ name ][ answer.ids[ i ] ] )
				table.remove( game.hands[ name ], answer.ids[ i ] )
			end

			drawCards( name )
		end

		game.answers = { }
		game.answersList = nil
		game.votes = { }

		table.remove( game.questions, 1 )

		if #game.questions == 0 then
			game.questions = table.random( #black )
		end
	end

	io.writeFile( "data/cah/state.json", json.encode( game ) )
end

chat.every( 60 * 5, advanceGame )

chat.listen( "reload", function()
	io.writeFile( "data/cah/state.json", json.encode( game ) )
end )
