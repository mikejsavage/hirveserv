Current limitations
-------------------

zChat might work but is 100% untested.

I am using flatfiles instead of a real database and don't make any
effort to ensure consistency in the event of a write failing amongst
probably multiple other awful flaws.


Security
--------

MM2k/zMud chat is unencrypted so a sysadmin/agency will be able to read
your password and chats in plaintext and insert/modify messages. That
said, this is literally a chat server for MUD clients so it is extremely
unlikely anyone will actually care to do this.

Once server side, passwords are bcrypted and salted and etc so
relatively safe if the server is compromised.

Modules/configs are not sanity checked before loading them so obviously
it is on you to check for malicious code in things you didn't write
yourself.

If started as root, hirveserv will inspect the `chroot`/`runas`
configuration settings and chroot into its own directory or drop
privilidges to the given user as appropriate. Note that chrooting means
you will be unable to load any new Lua modules on the fly.


Upgrading
---------

On the 25th Dec 2015, hirveserv transitioned into a more
traditional/proper filesystem layout, with the binary in `$PATH`, the
config in `/etc`, and the data/modules in `/var`. Everything inside the
data directory should be moved to `/var/lib/hirveserv` (or whatever you
set `dataDir` to), and so should the modules directory. For example,
your filesystem might contain `/var/lib/hirveserv/board` and
`/var/lib/hirveserv/modules`.

If you are running a version of hirveserv released before 29th Oct 2015
and `data/board.tct` exists, you will need to run `tokyo-to-json.lua` to
update the bulletin board to use the new format before loading the new
module.

If you are running a version of hirveserv from before the total rewrite
(`data/users.sq3` exists) then you will need to run the latest old
version of hirveserv to update the database to its most recent format
(commit `df9fad72aa`) then run the supplied `sq3-to-json.lua` to convert
it to the new flatfile format.


Overview
--------

### Open source

When I get bored of working on it, the project isn't dead and worthless
and people can verify that I'm not doing anything malicious.

### Modular

hirveserv was designed to make it easy to add features. Most of the out
of the box functionality is implemented in exactly the same way as any
extensions should be written.

### Lightweight

Both in terms of code and runtime usage. Lua is a reasonably terse
language and renowned for being very light itself, so I kind of get this
for free.

### Powerful out of the box

An incomplete list of features:

* authentication
  * fine-grained access control
  * password and IP authentication
  * temporary authentication
* on the fly reloading
  * reload modules and hop clients onto new code without having to kick
    everyone off
* alias recognition
  * `ch !cmd` instead of `/chat 1 cmd`. Is more useful than it sounds
* built in text editor
  * isn't horrific to use (see above)
  * isn't tied to any specific feature
  * can be summoned in a few lines of code
* bulletin board
  * #hashtags
* wiki
  * store walkthroughs/holders of important items/calendars/etc
* reps silencing
  * if everyone reports the same event, gag all but the first one
  * currently only setup for Medievia but easy enough to modify
  * big spam reduction for PvP
* [Cards Against Humanity](http://cardsagainsthumanity.com/)
* scripts repository
  * users can upload scripts to the server
  * other users can then install scripts with one command
  * bugs people when installed scripts are updated

And if you don't want any of this you can just delete/rename the modules
as appropriate.


Dependencies
------------

- lua >= 5.1, lua-ev, lua-cjson (`luarocks install lua-ev`, `luarocks
  install lua-cjson`)
- lua-bcrypt for auth (`luarocks install bcrypt`)
- lua-setuid for privilege dropping (`luarocks install setuid`)
- lua-arc4random for strong randomness (`luarocks install arc4random`)
- whatsit for WhatsApp integration


Running
-------

1. Run `make` and put the resulting hirveserv binary somewhere in
   `$PATH`.

2. Create `/etc/hirveserv.conf`, for example:

	name = "winnerserv"
	port = 4055
	auth = false
	chroot = true
	runas = "chat"

  See `src/config.lua` for a full list of settings and their defaults.

3. Move the modules folder and `data/cah` into `/var/lib/hirveserv` (or
   whatever you set `dataDir` to in the config).

On first run it will prompt you to create an admin account and give you
a password for it, which you should be able to connect normally with.
You can then `/chat 1 help` to get a list of commands.

If you would like to run more than instance simultaneously, hirveserv
looks at its first command line argument for an alternative config
location, which can point to its own data directory.
