local GagFor = 2

local patterns = {
	{
		"reports (.-) is PLAGUED",
		"reports: (.-) is PLAGUED",
		"reports: (.-) has been PLAGUED!",
		"%[([^%[]-)%] has been Plagued",
		"%[([^%[]-) has been plagued%]",
		"watches (.-) get PLAGUED!",
		"notices (.-) get PLAGUED!",
		"REPORTS %-> %[(.-)%] is %[PLAGUED%]",
		"%- %[(.-)%]%[Plagued%]",
		", '%((.-)%)%-%(Plagued%) at",
		"%((.-)%) got %(PLAGUED%) at",
	},
	{
		"reports (.-) is DISPELLED !",
		"reports: (.-) SANCTUARY has faded!",
		"%[([^%[]-)%] has lost Sanctury",
		"%[([^%[]-) has been dispelled%] %[sanctuary%]",
		"watches as (.-) loses SANCTUARY!",
		"notices (.-) is DISPELLED!",
		"REPORTS %-> %[(.-)%] is %[DISPELLED%]",
		"chats to everybody, '(.-)'s has just been DISPELLED!",
		"%- %[(.-)%]%[Sanc%]%[Dispelled%]",
		", '%((.-)%)%-%(Sanctuary%)%(Dispelled%) at",
		"chats to everybody, '%[(.-)'s%] has been Dispelled!",
		"%((.-)'s%) %(SANCTUARY%) got %(DISPELLED%) at",
		"' .(.-)'s. ASS has no .SANCTUARY.",
	},
	{
		"reports (.-) just TELEPORTED !",
		"reports: (.-) has just TELEPORTED",
		"notices (.-) just TELEPORTED away!",
		"watches as (.-) TELEPORTS away!",
		"REPORTS %-> %[(.-)%] %[TELEPORTED%]",
		"%- %[(.-)%]%[Teleported%]",
		", '%((.-)%)%-%(Teleported%) at",
		"%((.-)%) %(TELEPORTED%) at",
	},
	{
		"reports (.-) is BLINDED !",
		"reports: (.-) is BLIND!",
		"reports: (.-) has been BLINDED!",
		"%[([^%[]-) has been blinded%]",
		"%[([^%[]-)%] has been Blinded",
		"watches (.-) get BLINDED!",
		"notices (.-) get BLINDED!",
		"REPORTS %-> %[(.-)%] is %[BLIND%]",
		"%- %[(.-)%]%[Blinded%]",
		", '%((.-)%)%-%(Blinded%) at",
		"%((.-)%) got %(BLINDED%) at",
	},
	{
		"reports (.-) is CURSED !",
		"reports: (.-) is CURSED!",
		"%[([^%[]-) has been cursed%]",
		"%[(^%[]-)%] has been Cursed",
		"watches (.-) get CURSED!",
		"REPORTS %-> %[(.-)%] is %[CURSED%]",
		", '%((.-)%)%-%(Cursed%) at",
		"%((.-)%) got %(CURSED%) at",
	},
	{
		"reports (.-) is CHILLED !",
		"REPORTS %-> %[(.-)%] is %[CHILLED%]",
		", '%((.-)%)%-%(Chilled%) at",
		"%((.-)%) got %(CHILLED%) at",
	},
	{
		"reports (.-) is POISONED !",
		"reports: (.-) is POISONED!",
		"%[([^%[]-) has been poisoned%]",
		"%[([^%[]-)%] has been Poisoned",
		"watches as (.-) becomes POISONED!",
		"REPORTS %-> %[(.-)%] is %[POISONED%]",
		"%- %[(.-)%]%[Poisoned%]",
		", '%((.-)%)%-%(Poisoned%) at",
		"%((.-)%) got %(POISONED%) at",
	},
	{
		"reports (.-) is WEAKENED !",
		"reports (.-) is WEAKNED !",
		"reports: (.-) is WEAKENED!",
		"REPORTS %-> %[(.-)%] is %[WEAKENED%]",
		"%[([^%[]-) has been weakened%]",
		", '%((.-)%)%-%(Weakened%) at",
		"%((.-)%) got %(WEAKENED%) at",
	},
	{
		"reports .- just %-RESURRECTED%- (.-) !",
		"reports .- just %+%+RESSED%+%+ (.-) !",
		"reports .- just %+%+RESSED%+%+(.-) !",
		"REPORTS %-> %[(.-)%] %[RESSED%] by",
		"%*%*%* (.-) was just RESURRECTED",
		"%((.-)%) has been %(Resurrected%) at",
	},
	{
		"reports .- just HANDSED (.-) !",
		"sees .- HANDS (.-) out of FORMATION!",
		"REPORTS %-> %[(.-)%] has been %[HANDSED%] at",
		":  (.-) has been hit with HAND OF WIND by",
		"%(.-%) %(HANDSED%) %((.-)%) at",
	},
	{
		"just %-RESCUED%- (.-) !",
	},
	{
		"watches (.+) get MUFFLED!",
		"reports (.+) is MUFFLED !",
		"%[([^%[]-)%] has been Muffled",
		"REPORTS %-> %[(.-)%] is %[MUFFLED%] at",
		"%- %[(.-)%]%[Muffled%]",
	},
	{
		"just saw (.-) recite a teleport !",
	},
}

local silence = {
	"reports .- is FAERIED !",
	"reports: .- is FAERIE FIRED!",
	"watches .- get FAERIE FIRED!",
	"notices .- get FAERIED!",
	"%[.- has been faerie fired%]",
	"REPORTS %-> %[.-%] is %[FAERIED%]",
	"got %(FAERIE FIRED%) at",
	"%((.-)%)%-%(Faerie Fired%) at",

	"I have been Sanced",
	"I have lost Sanctuary",
	"I have been Disarmed by",

	"%[.-%]%[Imaged%]",

	"lybicat.+TRIP",
	"lybicat.+trip",
	"TRIP.+lybicat",
	"trip.+lybicat",
}

local badTargets = {
	[ "My" ] = true,
	[ "I'm" ] = true,
	[ "Someone" ] = true,
	[ "someone" ] = true,
}

local reps = { }

for _, spell in ipairs( patterns ) do
	table.insert( reps, {
		patterns = spell,
		last = { },
	} )
end

local function targetFromRep( spell, message )
	for _, pattern in ipairs( spell.patterns ) do
		local target = message:match( pattern )

		if target then
			return target
		end
	end

	return nil
end

local function isRepeatRep( message, now )
	for _, spell in ipairs( reps ) do
		local target = targetFromRep( spell, message )

		if target and not badTargets[ target ] then
			if spell.last.target == target and spell.last.gagUntil >= now then
				spell.last.gagUntil = now + GagFor

				return true
			end

			spell.last.target = target
			spell.last.gagUntil = now + GagFor

			return false
		end
	end

	return false
end

local function isSilenced( message )
	for _, pattern in ipairs( silence ) do
		if message:match( pattern ) then
			return true
		end
	end

	return false
end

chat.listen( "chat", function( from, message, recipients )
	message = message:stripVT102()

	local now = chat.now()
	if isRepeatRep( message, now ) or isSilenced( message ) then
		table.clear( recipients )
	end
end )
