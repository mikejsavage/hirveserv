#! /usr/bin/lua

require( "tokyocabinet" )
require( "lfs" )

lfs.mkdir( "data/board" )

local json = require( "cjson.safe" )

local posts = tokyocabinet.tdbnew()

posts:setxmsiz( 8 * 1024 )
posts:open( "data/posts.tct", posts.OREADER )
posts:setindex( "date", posts.ITDECIMAL + posts.ITKEEP )

local query = tokyocabinet.tdbqrynew( posts )
query:setorder( "", query.QONUMDESC )
local result = query:search()

for _, id in ipairs( result ) do
	local post = posts[ id ]

	post.date = tonumber( post.date )

	local tags = post.tags
	post.tags = { }
	for tag in tags:gmatch( "(%S+)" ) do
		table.insert( post.tags, tag )
	end

	local file = io.open( "data/board/" .. id .. ".json", "w" )
	file:write( json.encode( post ) )
	file:close()
end
