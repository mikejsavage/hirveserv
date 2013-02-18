local db = ...

db( "ALTER TABLE ipauths RENAME TO oldipauths" )()

db( [[CREATE TABLE ipauths (
	userid INTEGER,
	ip STRING NOT NULL,
	mask STRING DEFAULT "255.255.255.255",
	FOREIGN KEY( userid ) REFERENCES users( userid ),
	UNIQUE( userid, ip, mask ) ON CONFLICT IGNORE
)]] )()

for userid, auth in db( "SELECT userid, ip FROM oldipauths" ) do
	db( "INSERT INTO ipauths ( userid, ip ) VALUES ( ?, ? )", userid, auth )()
end

db( "DROP TABLE oldipauths" )()
