local modules = require( "include.modules" )

local _M = { }

local function generic( tag )
	return function( form, ... )
		local msg = form:format( ... )

		print( "[" .. tag:upper() .. "]", form:format( ... ) )
		modules.fireEvent( "error", tag, msg )
	end
end

_M.error = generic( "error" )
_M.warn = generic( "warn" )
_M.info = generic( "info" )

function _M.check( test, form, ... )
	if not test then
		_M.error( form, ... )
	end
end

return _M
