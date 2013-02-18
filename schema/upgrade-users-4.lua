local db = ...

db( "ALTER TABLE privs RENAME TO oldprivs" )()
db( "ALTER TABLE settings RENAME TO oldsettings" )()

db( [[CREATE TABLE privs (
	userid INTEGER,
	priv STRING,
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, priv ) ON CONFLICT IGNORE
)]] )()

db( [[CREATE TABLE settings (
	userid INTEGER,
	setting STRING NOT NULL,
	value STRING,
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, setting ) ON CONFLICT REPLACE
)]] )()

for userid, priv in db( "SELECT userid, priv FROM oldprivs" ) do
	db( "INSERT INTO privs ( userid, priv ) VALUES ( ?, ? )", userid, priv )()
end

for userid, setting, value in db( "SELECT userid, setting, value FROM oldsettings" ) do
	db( "INSERT INTO settings ( userid, setting, value ) VALUES ( ?, ?, ? )", userid, setting, value )()
end

db( "DROP TABLE oldprivs" )()
db( "DROP TABLE oldsettings" )()
