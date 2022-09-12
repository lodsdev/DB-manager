
local myDbSQLite
local DBManager = DBManagerClass()
local DBTable = DBTableClass()
local SQLRepo = SQLRepoClass()

addEventHandler('onResourceStart', resourceRoot, function()
    myDbSQLite = DBManager:new('sqlite', 'database/file.db')
   
    local myTable = DBTable:new(myDbSQLite:getDB(), 'users')
    myTable:create([[
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name VARCHAR(255), 
        age INTEGER
    ]])

    local sqlRepo = SQLRepo:new(myDbSQLite, myTable)
    sqlRepo:update('name', 'John', 'id', 1)
end)