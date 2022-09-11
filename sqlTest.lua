
local myDbSQLite
local myDbMySQL
local DBManager = DBManagerClass()

addEventHandler('onResourceStart', resourceRoot, function()
    myDbSQLite = DBManager:new('sqlite', 'database/file.db')
    
    myDbMySQL = DBManager:new('mysql', {
        host = 'localhost',
        port = 3306,
        username = 'root',
        password = '',
        database = 'mta'
    })

    iprint(myDbSQLite:getDB(), myDbMySQL:getDB())
end)