local modules = require( "include.modules" )

chat.command( "reload", "all", function( client )
	chat.event( "reload" )

	local ok, err = pcall( modules.load )

	if not ok then
		client:msg( "Failed: %s", err )
	else
		client:msg( "Reloaded." )
	end
end, "Try to reload modules, Hirve only" )

chat.command( "hop", "all", function( client )
	client:msg( "Hopping..." )

	for _, client in ipairs( chat.clients ) do
		if not client:hop() then
			break
		end
	end

	client:msg( "Done!" )
end, "Hop clients onto new coroutines, Hirve only" )
