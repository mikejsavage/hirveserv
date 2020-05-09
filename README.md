Overview
--------

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
* websockets
  * web clients and regular clients both connect to a single port
* scripts repository
  * users can upload scripts to the server
  * other users can then install scripts with one command
  * bugs people when installed scripts are updated


Dependencies
------------

hirveserv depends on Lua, OpenSSL, libev (and -dev packages if your OS
uses those). hirveserv supports Lua 5.1 and onwards, but websockets only
work when using Lua 5.3 or newer. hirveserv also depends on some Lua
modules:

```sh
luarocks install https://raw.githubusercontent.com/brimworks/lua-ev/master/rockspec/lua-ev-scm-1.rockspec
luarocks install lua-cjson
luarocks install luafilesystem
luarocks install luasocket
luarocks install bcrypt
luarocks install arc4random
```


Running
-------

1. Install the dependences as listed above

2. Run `make` and put the resulting hirveserv binary somewhere in
   `$PATH`.

3. Create `/etc/hirveserv.conf`, for example:

        name = "winnerserv"
        port = 4055
        auth = false

  See `src/config.lua` for a full list of settings and their defaults.

4. Move the modules folder  into `/var/lib/hirveserv` (or whatever you
   set `dataDir` to in the config).

5. The first time you run hirveserv it will prompt you to make an admin
   account.

6. After that you can run hirveserv like any other service.

Once you've connected you can `/chat 1 help` to get a list of commands.

If you would like to run more than one instance simultaneously,
hirveserv looks at its first command line argument for an alternative
config location, which can point to its own data directory.


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
