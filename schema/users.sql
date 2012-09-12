CREATE TABLE IF NOT EXISTS users (
	userid INTEGER PRIMARY KEY,
	name STRING UNIQUE,
	password STRING
);

CREATE TABLE IF NOT EXISTS pending (
	name STRING UNIQUE,
	code STRING
);

CREATE TABLE IF NOT EXISTS privs (
	userid INTEGER,
	priv STRING
);

CREATE TABLE IF NOT EXISTS settings (
	userid INTEGER,
	setting STRING,
	value STRING
);

CREATE TABLE IF NOT EXISTS ipauths (
	userid INTEGER,
	ip STRING
);

CREATE INDEX IF NOT EXISTS idx_privs ON privs ( userid );
CREATE INDEX IF NOT EXISTS idx_settings ON settings ( userid );
CREATE INDEX IF NOT EXISTS idx_ipauths ON ipauths ( userid, ip );
