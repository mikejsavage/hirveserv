local GagFor = 2

local patterns = {
	{
		"reports TARGET is PLAGUED",
		"reports: TARGET is PLAGUED",
		"reports: TARGET has been PLAGUED!",
		"[TARGET] has been Plagued",
		"[TARGET has been plagued]",
		"watches TARGET get PLAGUED!",
		"notices TARGET get PLAGUED!",
		"REPORTS -> [TARGET] is [PLAGUED]",
		"- [TARGET][Plagued]",
		", '(TARGET)-(Plagued) at",
		"(TARGET) got (PLAGUED) at",
		"[TARGET has been PLAGUED!]",
	},
	{
		"reports TARGET is DISPELLED !",
		"reports: TARGET SANCTUARY has faded!",
		"[TARGET] has lost Sanctuary",
		"[TARGET has been dispelled] [sanctuary]",
		"watches as TARGET loses SANCTUARY!",
		"notices TARGET is DISPELLED!",
		"REPORTS -> [TARGET] is [DISPELLED]",
		"chats to everybody, 'TARGET's has just been DISPELLED!",
		"- [TARGET][Sanc][Dispelled]",
		", '(TARGET)-(Sanctuary)(Dispelled) at",
		"chats to everybody, '[TARGET's] has been Dispelled!",
		"(TARGET's) (SANCTUARY) got (DISPELLED) at",
		"' ??TARGET's?? ASS has no ??SANCTUARY??",
		"[TARGET has been DISPELLED!]",
	},
	{
		"[TARGET has been dispelled] [fireshield]",
		"reports: TARGET's FIRESHIELD has been dispelled.",
	},
	{
		"[TARGET has been dispelled] [iceshield]",
	},
	{
		"reports TARGET just TELEPORTED !",
		"reports: TARGET has just TELEPORTED",
		"notices TARGET just TELEPORTED away!",
		"watches as TARGET TELEPORTS away!",
		"REPORTS -> [TARGET] [TELEPORTED]",
		"- [TARGET][Teleported]",
		", '(TARGET)-(Teleported) at",
		"(TARGET) (TELEPORTED) at",
		"TARGET chants the magical words 'Seeyoulatamadafaka'!",
	},
	{
		"reports TARGET is BLINDED !",
		"reports: TARGET is BLIND!",
		"reports: TARGET has been BLINDED!",
		"[TARGET has been blinded]",
		"[TARGET] has been Blinded",
		"watches TARGET get BLINDED!",
		"notices TARGET get BLINDED!",
		"REPORTS -> [TARGET] is [BLIND]",
		"- [TARGET][Blinded]",
		", '(TARGET)-(Blinded) at",
		"(TARGET) got (BLINDED) at",
	},
	{
		"reports TARGET is CURSED !",
		"reports: TARGET is CURSED!",
		"[TARGET has been cursed]",
		"[TARGET] has been Cursed",
		"watches TARGET get CURSED!",
		"REPORTS -> [TARGET] is [CURSED]",
		", '(TARGET)-(Cursed) at",
		"(TARGET) got (CURSED) at",
	},
	{
		"reports TARGET is CHILLED !",
		"REPORTS -> [TARGET] is [CHILLED]",
		", '(TARGET)-(Chilled) at",
		"(TARGET) got (CHILLED) at",
	},
	{
		"reports TARGET is POISONED !",
		"reports: TARGET is POISONED!",
		"[TARGET has been poisoned]",
		"[TARGET] has been Poisoned",
		"watches as TARGET becomes POISONED!",
		"REPORTS -> [TARGET] is [POISONED]",
		"- [TARGET][Poisoned]",
		", '(TARGET)-(Poisoned) at",
		"(TARGET) got (POISONED) at",
		"[TARGET has been POISONED!]",
	},
	{
		"reports TARGET is WEAKENED !",
		"reports TARGET is WEAKNED !",
		"reports: TARGET is WEAKENED!",
		"REPORTS -> [TARGET] is [WEAKENED]",
		"[TARGET has been weakened]",
		", '(TARGET)-(Weakened) at",
		"(TARGET) got (WEAKENED) at",
	},
	{
		"reports BLAH just -RESURRECTED- TARGET !",
		"reports BLAH just ++RESSED++ TARGET !",
		"reports BLAH just ++RESSED++TARGET !",
		"REPORTS -> [TARGET] [RESSED] by",
		"*** TARGET was just RESURRECTED",
		"(TARGET) has been (Resurrected) at",
	},
	{
		"reports BLAH just HANDSED TARGET !",
		"sees BLAH HANDS TARGET out of FORMATION!",
		"REPORTS -> [TARGET] has been [HANDSED] at",
		":  TARGET has been hit with HAND OF WIND by",
		"(BLAH) (HANDSED) (TARGET) at",
	},
	{
		"just -RESCUED- TARGET !",
	},
	{
		"watches TARGET get MUFFLED!",
		"reports TARGET is MUFFLED !",
		"[TARGET] has been Muffled",
		"REPORTS -> [TARGET] is [MUFFLED] at",
		"- [TARGET][Muffled]",
		"[TARGET has been MUFFLED]",
		"[TARGET has been MUFFLED!]",
		"[TARGET IS MUFFLED!!]",
	},
	{
		"just saw TARGET recite a teleport !",
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

local function makePattern( x )
	return ( x:patternEscape():gsub( "BLAH", ".-" ):gsub( "%%%?%%%?", "." ):gsub( "TARGET", "([^%%[%%]%%(%%)%%*]-)" ) )
end

local badTargets = {
	[ "My" ] = true,
	[ "I'm" ] = true,
	[ "Someone" ] = true,
	[ "someone" ] = true,
}

local reps = { }

for _, spell in ipairs( patterns ) do
	local p = { }
	for _, pattern in ipairs( spell ) do
		table.insert( p, makePattern( pattern ) )
	end

	table.insert( reps, {
		patterns = p,
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

		if target == "HIRVETEST" then
			return true
		end

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
