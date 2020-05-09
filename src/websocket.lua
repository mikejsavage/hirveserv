local lpeg = require( "lpeg" )
local mime = require( "mime" ) -- part of luasocket
local sha1 = require( "sha1" )

local http_request_parser
do
	local key = ( 1 - lpeg.S( ":\r\n" ) ) ^ 1
	local value = ( 1 - lpeg.S( "\r\n" ) ) ^ 1
	local whitespace = lpeg.S( " \t" ) ^ 0
	local header = ( lpeg.C( key ) / string.lower ) * lpeg.P( ":" ) * whitespace * lpeg.C( value ) * whitespace * lpeg.P( "\r\n" )
	http_request_parser = lpeg.P( "GET / HTTP/1.1\r\n" ) * lpeg.Ct( lpeg.Ct( header ) ^ 0 ) * lpeg.P( "\r\n" ) * lpeg.Cp()
end

local _M = { }

function _M.handshake( data )
	local headers, len = http_request_parser:match( data )
	if not headers then
		return false
	end

	local version
	local key

	for _, header in ipairs( headers ) do
		if header[ 1 ] == "sec-websocket-version" then
			version = header[ 2 ]
		elseif header[ 1 ] == "sec-websocket-key" then
			key = header[ 2 ]
		end
	end

	if not key or version ~= "13" then
		return false
	end

	local accept = mime.b64( sha1( key .. "258EAFA5-E914-47DA-95CA-C5AB0DC85B11" ) )
	local response = ""
		.. "HTTP/1.1 101 Switching Protocols\r\n"
		.. "Upgrade: websocket\r\n"
		.. "Connection: Upgrade\r\n"
		.. "Sec-WebSocket-Accept: " .. accept .. "\r\n"
		.. "\r\n"

	return true, len, response
end

local function make_frame( opcode, data, fin )
	local result = string.char( bit32.bor( fin and 0x80 or 0, opcode ) )

	if #data <= 125 then
		result = result .. string.char( #data )
	elseif #data <= 0xFFFF then
		result = result .. string.pack( "<BI2", 126, #data )
	else
		result = result .. string.pack( "<BI8", 127, #data )
	end

	return result .. data
end

local function close( code, message )
	local data = string.pack( "<I2", code ) .. message
	return make_frame( 0x8, data, true )
end

function _M.parse_frame( data )
	local ok, frame, len = pcall( function()
		local frame = { }
		local pos = 1

		local b0, b1
		b0, b1, pos = string.unpack( "BB", data, pos )

		frame.FIN = bit32.band( b0, 0x80 )
		frame.RSV1 = bit32.band( b0, 0x40 )
		frame.RSV2 = bit32.band( b0, 0x20 )
		frame.RSV3 = bit32.band( b0, 0x10 )
		frame.opcode = bit32.band( b0, 0x0F )
		local MASK = bit32.band( b1, 0x80 )

		local data_length = bit32.band( b1, 0x7F )

		if data_length == 126 then
			data_length, pos = string.unpack( "<I2", data, pos )
		elseif data_length == 127 then
			data_length, pos = string.unpack( "<I8", data, pos )
		end

		if MASK == 0 then
			frame.data = data:sub( pos, pos + data_length )
			assert( #frame.data == data_length )
		else
			local key = { string.unpack( "BBBB", data, pos ) }
			table.remove( key, 5 )
			pos = pos + 4

			local unmasked = { }
			for i = 1, data_length do
				local byte
				byte, pos = string.unpack( "B", data, pos )
				table.insert( unmasked, string.char( bit32.bxor( byte, key[ ( ( i - 1 ) % 4 ) + 1 ] ) ) )
			end

			frame.data = table.concat( unmasked )
		end

		return frame, pos
	end )

	if not ok then
		return
	end

	return frame, len
end

-- returns keep open, data, response frame, expect_continuation
function _M.process_frame( frame, expect_continuation )
	if frame.RSV1 ~= 0 or frame.RSV2 ~= 0 or frame.RSV3 ~= 0 then
		return false, nil, close( 1002, "Reserved bits not zero" )
	end

	if ( frame.opcode >= 0x3 and frame.opcode <= 0x7 ) or frame.opcode >= 0xB then
		return false, nil, close( 1002, "Reserved opcode" )
	end

	if frame.opcode >= 0x8 then
		if #frame.data > 125 then
			return false, nil, close( 1002, "Data too long" )
		end

		if frame.FIN == 0 then
			return false, nil, close( 1002, "Fragmented control frame" )
		end
	end

	-- close frame
	if frame.opcode == 0x8 then
		return false
	end

	-- continuation frame
	if frame.opcode == 0x0 then
		if not expect_continuation then
			return false, nil, close( 1002, "Unexpected continuation frame" )
		end

		return true, frame.data, nil, frame.FIN == 0
	end

	-- text/binary frame
	if frame.opcode == 0x1 or frame.opcode == 0x2 then
		if expect_continuation then
			return false, nil, close( 1002, "Expected continuation frame" )
		end

		return true, frame.data, nil, frame.FIN == 0
	end

	-- ping
	if frame.opcode == 0x9 then
		return true, nil, make_frame( 0xa, frame.data, true ), expect_continuation
	end

	-- pong
	assert( frame.opcode == 0xa )
	return true, nil, nil, expect_continuation
end

function _M.text( data )
	return make_frame( 0x1, data, true )
end

function _M.binary( data )
	return make_frame( 0x2, data, true )
end

return _M
