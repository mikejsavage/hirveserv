local ev = require( "ev" )
local SIGINT = 2

local function onSigInt( loop, signal )
	loop:unloop()
end

ev.Signal.new( onSigInt, SIGINT ):start( chat.loop )
