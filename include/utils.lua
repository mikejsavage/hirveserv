getmetatable( "" ).__mod = function( self, form )
	if type( form ) == "table" then
		local ok, err = pcall( string.format, self, unpack( form ) )

		if not ok then
			print( self )
			for _, f in ipairs( form ) do
				print( "> " .. tostring( f ) )
			end
			assert( ok, err )
		end

		return self:format( unpack( form ) )
	end

	local ok, err = pcall( string.format, self, form )

	if not ok then
		print( self )
		print( "> " .. tostring( form ) )
		assert( ok, err )
	end

	return self:format( form )
end

function string.plural( count, plur, sing )
	return count == 1 and ( sing or "" ) or ( plur or "s" )
end

function string.startsWith( self, needle )
	return self:sub( 1, needle:len() ) == needle
end

function string.commas( num )
	num = tonumber( num )

	local out = ""

	while num > 1000 do
		out = ( ",%03d%s" ):format( num % 1000, out )

		num = math.floor( num / 1000 )
	end

	return tostring( num ) .. out
end

function string.trim( self )
	return self:match( "^%s*(.-)%s*$" )
end

function string.patternEscape( self )
	return self:gsub( "[.*%+-?$^%%%[%]%(%)]", "%%%1" )
end

function string.stripVT102( self )
	return self:gsub( "\27%[[%d;]*%a", "" )
end

function string.yn( self )
	local firstLetter = self:sub( 1, 1 )

	return firstLetter == "y" and "y" or ( firstLetter == "n" and "n" or nil )
end

function math.round( num )
	return math.floor( num + 0.5 )
end

function math.avg( a, b )
	return ( a + b ) / 2
end

function math.ipmask( ip, mask )
	local isplit = { ip:match( "^(%d+)%.(%d+)%.(%d+)%.(%d+)$" ) }
	local msplit = { mask:match( "^(%d+)%.(%d+)%.(%d+)%.(%d+)$" ) }
	local zeroing = false

	for i = 1, 4 do
		if zeroing then
			isplit[ i ] = 0
		elseif msplit[ i ] ~= "255" then
			local m = tonumber( msplit[ i ] )
			local n = 0

			if m == 0 then
				n = 8
			else
				-- count trailing 0 bits in m
				while m % 2 == 0 and m > 0 do
					m = math.floor( m / 2 )
					n = n + 1
				end
			end

			local e = 2 ^ n
			isplit[ i ] = math.floor( isplit[ i ] / e ) * e

			zeroing = true
		end
	end

	return table.concat( isplit, "." )
end

function io.readable( path )
	local file, err = io.open( path, "r" )

	if not file then
		return false, err
	end

	io.close( file )

	return true
end

function io.contents( path )
	local file, err = io.open( path, "r" )

	if not file then
		return nil, err
	end

	local contents = file:read( "*a" )

	file:close()

	return contents
end

function table.insertBy( self, value, cmp )
	local idx = 1

	while idx <= #self and not cmp( value, self[ idx ] ) do
		idx = idx + 1
	end

	table.insert( self, idx, value )
end

function table.removeValue( self, value )
	for i, elem in ipairs( self ) do
		if elem == value then
			table.remove( self, i )
			
			break
		end
	end
end

function table.sortByKey( self, key )
	table.sort( self, function( a, b )
		return a[ key ] < b[ key ]
	end )
end

function enforce( var, name, ... )
	local acceptable = { ... }
	local ok = false

	for _, accept in ipairs( acceptable ) do
		if type( var ) == accept then
			ok = true

			break
		end
	end

	if not ok then
		error( "argument `%s' to %s should be of type %s (got %s)" % { name, debug.getinfo( 2, "n" ).name, table.concat( acceptable, " or " ), type( var ) }, 2 )
	end
end

local ColourSequences = {
	d = 0,
	r = 31,
	g = 32,
	y = 33,
	b = 34,
	m = 35,
	c = 36,
	w = 37,
}

function chat.parseColours( message )
	message = assert( tostring( message ) )

	return ( message:gsub( "()#(l?)(%l)", function( patternPos, bold, sequence )
		if message:sub( patternPos - 1, patternPos - 1 ) == "#" then
			return
		end

		if bold == "l" then
			return "\27[1m\27[%dm" % { ColourSequences[ sequence ] }
		end

		return "\27[0m\27[%dm" % { ColourSequences[ sequence ] }
	end ):gsub( "##", "#" ) )
end

local function uconv( bytes, n )
	assert( n >= 0 and n < 2 ^ ( bytes * 8 ), "value out of range: " .. n )

	local output = ""

	for i = 1, bytes do
		output = output .. string.char( n % 256 )
		n = math.floor( n / 256 )
	end

	return output
end

function string.ushort( n )
	return uconv( 2, n )
end

function string.uint( n )
	return uconv( 4, n )
end
