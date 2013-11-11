local ev = require( "ev" )
local loop = ev.Loop.default

local SIGINT = 2

local function onSigInt( loop, signal )
	loop:unloop()
end

ev.Signal.new( onSigInt, SIGINT ):start( loop )
