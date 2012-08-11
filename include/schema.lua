local function createUsers( db )
	db( [[CREATE TABLE IF NOT EXISTS users (
		userid INTEGER PRIMARY KEY,
		name STRING UNIQUE,
		password STRING
	)]] )()

	db( [[CREATE TABLE IF NOT EXISTS privs (
		userid INTEGER,
		priv STRING
	)]] )()

	db( [[CREATE TABLE IF NOT EXISTS settings (
		userid INTEGER,
		setting STRING,
		value STRING
	)]] )()

	db( [[CREATE TABLE IF NOT EXISTS ipauths (
		userid INTEGER,
		ip STRING
	)]] )()

	db( [[CREATE INDEX IF NOT EXISTS idx_privs ON privs ( userid )]] )()
	db( [[CREATE INDEX IF NOT EXISTS idx_settings ON settings ( userid )]] )()
	db( [[CREATE INDEX IF NOT EXISTS idx_ipauths ON ipauths ( userid, ip )]] )()
end

local function createLogs( db )
end

return {
	users = createUsers,
	logs = createLogs,
}
