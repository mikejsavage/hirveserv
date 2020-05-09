local unpack_be32x16 = ">" .. string.rep( "I4", 16 )

return function( msg )
	local h0 = 0x67452301
	local h1 = 0xEFCDAB89
	local h2 = 0x98BADCFE
	local h3 = 0x10325476
	local h4 = 0xC3D2E1F0

	local bit_len = #msg * 8

	-- append "1" bit
	msg = msg .. string.char( 0x80 )

	-- pad to multiple of 64 minus 64bits
	local padding_len = ( 64 - ( #msg + 8 ) % 64 ) % 64
	msg = msg .. string.rep( string.char( 0 ), padding_len )

	-- append 64bit length
	msg = msg .. string.pack( ">I8", bit_len )
	assert( #msg % 64 == 0 )

	for i = 1, #msg, 64 do
		local words = { string.unpack( unpack_be32x16, msg, i ) }

		for j = 17, 80 do
			local xor = bit32.bxor( words[ j - 3 ], words[ j - 8 ], words[ j - 14 ], words[ j - 16 ] )
			words[ j ] = bit32.lrotate( xor, 1 )
		end

		local a = h0
		local b = h1
		local c = h2
		local d = h3
		local e = h4

		local function round( j, f, k )
			local temp = bit32.lrotate( a, 5 ) + f + e + k + words[ j ]
			e = d
			d = c
			c = bit32.lrotate( b, 30 )
			b = a
			a = temp
		end

		for j = 1, 20 do
			local f = bit32.bor( bit32.band( b, c ), bit32.band( bit32.bnot( b ), d ) )
			local k = 0x5A827999
			round( j, f, k )
		end

		for j = 21, 40 do
			local f = bit32.bxor( b, c, d )
			local k = 0x6ED9EBA1
			round( j, f, k )
		end

		for j = 41, 60 do
			local f = bit32.bor( bit32.band( b, c ), bit32.band( b, d ), bit32.band( c, d ) )
			local k = 0x8F1BBCDC
			round( j, f, k )
		end

		for j = 61, 80 do
			local f = bit32.bxor( b, c, d )
			local k = 0xCA62C1D6
			round( j, f, k )
		end

		h0 = h0 + a
		h1 = h1 + b
		h2 = h2 + c
		h3 = h3 + d
		h4 = h4 + e
	end

	-- truncate to 32bits
	h0 = bit32.band( h0, 0xFFFFFFFF )
	h1 = bit32.band( h1, 0xFFFFFFFF )
	h2 = bit32.band( h2, 0xFFFFFFFF )
	h3 = bit32.band( h3, 0xFFFFFFFF )
	h4 = bit32.band( h4, 0xFFFFFFFF )

	return string.pack( ">I4I4I4I4I4", h0, h1, h2, h3, h4 )
end
