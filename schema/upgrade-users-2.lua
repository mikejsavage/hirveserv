local db = ...

db( "ALTER TABLE ipauths RENAME TO oldipauths" )()

db( [[CREATE TABLE IF NOT EXISTS ipauths (
	userid INTEGER,
	ip STRING NOT NULL,
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, ip )
)]] )()

for userid, auth in db( "SELECT DISTINCT userid, ip FROM oldipauths" ) do
	db( "INSERT INTO ipauths ( userid, ip ) VALUES ( ?, ? )", userid, auth )()
end

db( "DROP TABLE oldipauths" )()
