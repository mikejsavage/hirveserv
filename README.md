Current limitations
-------------------

zMud is totally broken.

It would be nice to make it chroot/setuid unnecessary privilidges away
on startup.

I am using flatfiles instead of a real database and don't make any
effort to ensure consistency in the event of a write failing amongst
probably multiple other awful flaws.


Security
--------

MM2k/zMud chat is unencrypted so a sysadmin/agency will be able to read
your password and chats in plaintext and insert/modify messages. That
said, this is literally a chat server for MUD clients so it is extremly
unlikely anyone will actually care to do this.

Once server side, passwords are bcrypted and salted and etc so
relatively safe if the server is compromised.

Modules/configs are not sanity checked before loading them so obviously
it is on you to check for malicious code in things you didn't write
yourself.


Dependancies
------------

lua 5.1, libev, lua-ev, lua-cjson, lua-bcrypt


Running
-------

Create config.lua, for example:

	name = "winnerserv"
	port = 4055
	auth = false

See `include/defaults.lua` for a list of settings.

On first run it will prompt you to create an admin account and give you
a password for it, which you should be able to connect normally with.
You can then `/chat 1 help` to get a list of commands.

If you are running a version of hirveserv from before the total rewrite
(`data/users.sq3` exists) then you will need to run the latest old
version of hirveserv to update the database to its most recent format (commit
`df9fad72aa`) then run the supplied `sq3-to-json.lua` to convert it to the new
flatfile format.
