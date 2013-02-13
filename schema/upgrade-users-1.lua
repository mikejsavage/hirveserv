local db = ...

db( "ALTER TABLE users RENAME TO oldusers" )()
db( "ALTER TABLE privs RENAME TO oldprivs" )()
db( "ALTER TABLE settings RENAME TO oldsettings" )()
db( "ALTER TABLE ipauths RENAME TO oldipauths" )()

db( [[CREATE TABLE IF NOT EXISTS users (
	userid INTEGER PRIMARY KEY,
	name STRING UNIQUE NOT NULL,
	password STRING,
	isPending BOOLEAN DEFAULT 1
)]] )()

db( [[CREATE TABLE IF NOT EXISTS privs (
	userid INTEGER,
	priv STRING,
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, priv )
)]] )()

db( [[CREATE TABLE IF NOT EXISTS settings (
	userid INTEGER,
	setting STRING NOT NULL,
	value STRING,
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, setting )
)]] )()

db( [[CREATE TABLE IF NOT EXISTS ipauths (
	userid INTEGER,
	ip STRING NOT NULL,
	FOREIGN KEY( userid ) REFERENCES users( userid )
)]] )()

db( "CREATE INDEX IF NOT EXISTS idx_privs ON privs ( userid )" )()
db( "CREATE INDEX IF NOT EXISTS idx_settings ON settings ( userid )" )()
db( "CREATE INDEX IF NOT EXISTS idx_ipauths ON ipauths ( userid, ip )" )()

for userid, name, password in db( "SELECT userid, name, password FROM oldusers" ) do
	db( "INSERT INTO users ( userid, name, password, isPending ) VALUES ( ?, ?, ?, 0 )", userid, name, password )()
end

for name, code in db( "SELECT name, code FROM pending" ) do
	if not name:match( " " ) then
		local salt = bcrypt.salt( chat.config.bcryptRounds )
		local digest = bcrypt.digest( code, salt )

		db( "INSERT INTO users ( name, password ) VALUES( ?, ? )", name, digest )()
	end
end

for userid, priv in db( "SELECT DISTINCT userid, priv FROM oldprivs" ) do
	db( "INSERT INTO privs ( userid, priv ) VALUES ( ?, ? )", userid, priv )()
end

for userid, setting, value in db( "SELECT userid, setting, value FROM oldsettings" ) do
	db( "INSERT INTO settings ( userid, setting, value ) VALUES ( ?, ?, ? )", userid, setting, value )()
end

db( "DROP TABLE oldusers" )()
db( "DROP TABLE pending" )()
db( "DROP TABLE oldprivs" )()
db( "DROP TABLE oldsettings" )()
db( "DROP TABLE oldipauths" )()
