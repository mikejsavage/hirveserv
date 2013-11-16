local ev = require( "ev" )
local loop = ev.Loop.default

local GagFor = 2

local patterns = {
	{
		"reports (.-) is PLAGUED !",
		"reports: (.-) is PLAGUED",
		"%[(.-)%] has been Plagued",
		"%[(.-) has been plagued%]",
		"watches (.-) get PLAGUED!",
		"notices (.-) get PLAGUED!",
	},
	{
		"reports (.-) is DISPELLED !",
		"reports: (.-) SANCTUARY has faded!",
		"%[(.-)%] has lost Sanctury",
		"%[(.-) has been dispelled%] %[Sanctuary%]",
		"watches as (.-) loses SANCTUARY!",
		"notices (.-) is DISPELLED!",
	},
	{
		"reports (.-) just TELEPORTED !",
		"reports: (.-) has just TELEPORTED",
		"watches as (.-) TELEPORTS away!",
	},
	{
		"reports (.-) is BLINDED !",
		"reports: (.-) is BLIND!",
		"%[(.-) has been blinded%]",
		"watches (.-) get BLINDED!",
		"notices (.-) get BLINDED!",
	},
	{
		"reports (.-) is CURSED !",
		"reports: (.-) is CURSED!",
		"%[(.-) has been cursed%]",
		"watches (.-) get CURSED!",
	},
}

local reps = { }

local silence = {
	"reports .- is FAERIED !",
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
			
chat.listen( "chatAll", function( from, message, recipients )
	message = message:stripVT102()

	local now = loop:update_now()

	if isRepeatRep( message, now ) or isSilenced( message ) then
		table.clear( recipients )
	end
end )
