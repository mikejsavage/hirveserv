#! /usr/bin/lua

local json = require( "cjson" )
local lfs = require( "lfs" )
local bcrypt = require( "bcrypt" )

function io.readFile( path )
	local file = assert( io.open( path, "r" ) )
	local contents = assert( file:read( "*a" ) )
	assert( file:close() )

	return contents
end

local words_file = io.readFile( "include/words.lua" )
local words = { }

for word in words_file:gmatch( "\"(.-)\"" ) do
	table.insert( words, word )
end

for file in lfs.dir( "data/users" ) do
	if file:match( "%.json$" ) then
		local user = json.decode( io.readFile( "data/users/" .. file ) )

		for _, word in ipairs( words ) do
			if bcrypt.verify( word, user.password ) then
				print( file )
			end
		end

		local name = file:match( "^(.+)%.json$" )
		if bcrypt.verify( name, user.password ) then
			print( file, "name" )
		end
		if bcrypt.verify( name:reverse(), user.password ) then
			print( file, "eman" )
		end
	end
end
