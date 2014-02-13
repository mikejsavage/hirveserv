-- TODO: this is awful
getmetatable( "" ).__mod = function( self, form )
	if type( form ) == "table" then
		local ok, err = pcall( string.format, self, unpack( form ) )

		if not ok then
			print( self )
			for _, f in ipairs( form ) do
				print( "> " .. tostring( f ) )
			end
			error( err, 2 )
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

function string.commas( num )
	num = tonumber( num )

	local out = ""

	while num >= 1000 do
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

-- TODO: sucks
function string.trimVT102( self )
	while self:match( "^\27%[[%d;]*%a" ) do
		self = self:gsub( "^\27%[[%d;]*%a", "" )
	end

	while self:match( "\27%[[%d;]*%a$" ) do
		self = self:gsub( "\27%[[%d;]*%a$", "" )
	end

	return self
end

function math.round( num )
	return math.floor( num + 0.5 )
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

function io.writeFile( path, contents )
	local file = assert( io.open( path, "w" ) )
	assert( file:write( contents ) )
	assert( file:close() )
end

function table.insertBy( self, value, cmp )
	local idx = 1

	while idx <= #self and not cmp( self[ idx ] ) do
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

function table.sortByKey( self, key, desc )
	if desc then
		table.sort( self, function( a, b )
			return a[ key ] > b[ key ]
		end )
	else
		table.sort( self, function( a, b )
			return a[ key ] < b[ key ]
		end )
	end
end

function table.clear( self )
	for k in pairs( self ) do
		self[ k ] = nil
	end
end

function table.random( n )
	local shuffled = { }

	for i = 1, n do
		shuffled[ i ] = i
	end

	for i = n, 2, -1 do
		local rand = math.random( i )
		shuffled[ i ], shuffled[ rand ] = shuffled[ rand ], shuffled[ i ]
	end

	return shuffled
end

function table.shuffle( self, n )
	n = n or #self

	for i = n, 2, -1 do
		local rand = math.random( i )
		self[ i ], self[ rand ] = self[ rand ], self[ i ]
	end
end

function table.keys( self )
	local keys = { }

	for k in pairs( self ) do
		table.insert( keys, k )
	end

	return keys
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
		error( "argument `%s' to %s should be of type %s (got %s)" % { name, debug.getinfo( 2, "n" ).name, table.concat( acceptable, " or " ), type( var ) }, 3 )
	end
end

-- TODO: sucks
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

-- TODO: sucks
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
