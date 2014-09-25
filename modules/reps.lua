local ev = require( "ev" )
local loop = ev.Loop.default

local GagFor = 2

local patterns = {
	{
		"reports (.-) is PLAGUED !",
		"reports: (.-) is PLAGUED",
		"reports: (.-) has been PLAGUED!",
		"%[([^[]-)%] has been Plagued",
		"%[([^[]-) has been plagued%]",
		"watches (.-) get PLAGUED!",
		"notices (.-) get PLAGUED!",
		"REPORTS %-> %[(.-)%] is %[PLAGUED%]",
	},
	{
		"reports (.-) is DISPELLED !",
		"reports: (.-) SANCTUARY has faded!",
		"%[([^[]-)%] has lost Sanctury",
		"%[([^[]-) has been dispelled%] %[sanctuary%]",
		"watches as (.-) loses SANCTUARY!",
		"notices (.-) is DISPELLED!",
		"REPORTS %-> %[(.-)%] is %[DISPELLED%]",
		"chats to everybody, '(.-)'s has just been DISPELLED!",
	},
	{
		"reports (.-) just TELEPORTED !",
		"reports: (.-) has just TELEPORTED",
		"notices (.-) just TELEPORTED away!",
		"watches as (.-) TELEPORTS away!",
		"REPORTS %-> %[(.-)%] %[TELEPORTED%]",
	},
	{
		"reports (.-) is BLINDED !",
		"reports: (.-) is BLIND!",
		"reports: (.-) has been BLINDED!",
		"%[([^[]-) has been blinded%]",
		"%[([^[]-)%] has been Blinded",
		"watches (.-) get BLINDED!",
		"notices (.-) get BLINDED!",
		"REPORTS %-> %[(.-)%] is %[BLIND%]",
	},
	{
		"reports (.-) is CURSED !",
		"reports: (.-) is CURSED!",
		"%[([^[]-) has been cursed%]",
		"watches (.-) get CURSED!",
		"REPORTS %-> %[(.-)%] is %[CURSED%]",
	},
	{
		"reports (.-) is CHILLED !",
		"REPORTS %-> %[(.-)%] is %[CHILLED%]",
	},
	{
		"reports (.-) is POISONED !",
		"reports: (.-) is POISONED!",
		"%[([^[]-) has been poisoned%]",
		"%[([^[]-)%] has been Poisoned",
		"watches as (.-) becomes POISONED!",
		"REPORTS %-> %[(.-)%] is %[POISONED%]",
	},
	{
		"reports (.-) is WEAKENED !",
		"reports (.-) is WEAKNED !",
		"reports: (.-) is WEAKENED!",
		"REPORTS %-> %[(.-)%] is %[WEAKENED%]",
		"%[([^[]-) has been weakened%]",
	},
	{
		"reports .- just %-RESURRECTED%- (.-) !",
		"reports .- just %+%+RESSED%+%+ (.-) !",
		"REPORTS %-> %[(.-)%] %[RESSED%] by",
	},
	{
		"reports .- just HANDSED (.-) !",
		"sees .- HANDS (.-) out of FORMATION!",
		"REPORTS %-> %[(.-)%] has been %[HANDSED%] at",
	},
	{
		"just %-RESCUED%- (.-) !",
	},
	{
		"watches (.+) get MUFFLED!",
		"reports (.+) is MUFFLED !",
		"%[([^[]-)%] has been Muffled",
	},
}

local reps = { }

local silence = {
	"reports .- is FAERIED !",
	"reports: .- is FAERIE FIRED!",
	"watches .- get FAERIE FIRED!",
	"notices .- get FAERIED!",
	"%[.- has been faerie fired%]",
	"REPORTS %-> %[.-%] is %[FAERIED%]",

	"I have been Sanced",
	"I have lost Sanctuary",
	"I have been Disarmed by",
}

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

		if target then
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

	local now = loop:update_now()

	if isRepeatRep( message, now ) or isSilenced( message ) then
		table.clear( recipients )
	end
end )
