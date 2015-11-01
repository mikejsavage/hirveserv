local hours = 60 * 60
local days = 24 * hours

local medOffset = -5 * hours

local newmoonPeriod = 15 * days
local eclipsePeriod = 30 * days

local newmoonReference = 1446891046
local eclipseReference = 1446958546

local function niceTime( ts )
	local unit = "second"
	local a = "a"
	local colour = "#lg"

	if ts >= days then
		unit = "day"
		colour = "#lr"
		ts = ts / days
	elseif ts >= hours then
		unit = "hour"
		a = "an"
		colour = "#ly"
		ts = ts / hours
	elseif ts >= 60 then
		unit = "minute"
		ts = ts / 60
	end

	ts = math.floor( ts )

	return colour .. ( ts == 1 and ( "%s %s" % { a, unit } ) or ( "%s %ss" % { ts, unit } ) )
end

chat.command( "fae", nil, function( client )
	local now = os.time() + medOffset

	local timeToNM = newmoonPeriod - ( ( now - newmoonReference ) % newmoonPeriod )
	local timeToEC = eclipsePeriod - ( ( now - eclipseReference ) % eclipsePeriod )

	-- med updates the next eclipse time early. this might lead to bad codes.
	if timeToEC < 12 * hours then
		timeToEC = timeToEC + eclipsePeriod
	end

	local daysToNM = math.floor( timeToNM / days )
	local daysToEC = math.floor( timeToEC / days )

	local timeToChange = math.min( timeToNM % days, timeToEC % days )

	local result = {
		"Fae orb combos:",
		"You should check the current/newmoon/eclipse times against Med's #lmtime#lw command.",
		"If they're different then the codes are wrong.",
		"",
		"#lwNow:     #lr%s" % os.date( "%a %b %d %H:%M:%S %Y", now ),
		"#lwNewmoon: #lr%s" % os.date( "%a %b %d %H:%M:%S %Y", now + timeToNM ),
		"#lwEclipse: #lr%s" % os.date( "%a %b %d %H:%M:%S %Y", now + timeToEC ),
		"",
		"#lmThese codes change in %s" % niceTime( timeToChange ),
		"#lwXPXP:      #lg%2d %2d %2d" % { daysToEC + 2, daysToNM + 2,  2 },
		"#lwRemstorms: #ly%2d %2d %2d" % { daysToEC + 3, daysToNM + 6, 90 },
		"#lwRainstorm: #lc%2d %2d %2d" % { daysToEC + 3, daysToNM + 1, 63 },
	}

	client:msg( result )
end, "Show fae combos" )
