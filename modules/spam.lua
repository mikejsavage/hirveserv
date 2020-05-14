local recent_messages = { }

chat.listen( "chat", function( from, _, recipients )
	if not recent_messages[ from ] then
		recent_messages[ from ] = { }
	end

	local now = chat.now()
	table.insert( recent_messages[ from ], 1, now )

	for i = #recent_messages[ from ], 1, -1 do
		if now - recent_messages[ from ][ i ] >= 0.5 then
			table.remove( recent_messages[ from ], i )
		else
			break
		end
	end

	local n = #recent_messages[ from ]
	if n >= 10 then
		table.clear( recipients )
	end

	if n >= 15 then
		recent_messages[ from ] = nil
		chat.msg( "#ly%s#lw was kicked for spam.", from.name )
		from:kill()
	elseif n == 10 then
		from:msg( "Stop spamming" )
	elseif n == 0 then
		recent_messages[ from ] = nil
	end
end )

chat.listen( "disconnect", function( client )
	recent_messages[ client ] = nil
end )
