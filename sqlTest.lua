
local myDB
local DBManager = DBManagerClass()
local DBTable = DBTableClass()
local SQLRepo = SQLRepoClass()
local TableRepo = TableRepoClass()

addEventHandler('onResourceStart', resourceRoot, function()
    myDB = DBManager:new('sqlite', 'database/file.db')
   
    myTable = DBTable:new(myDB:getDB(), 'users')
    myTable:create([[
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name VARCHAR(255), 
        age INTEGER
    ]])

    mySQLRepo = SQLRepo:new(myDB, myTable)
    myRepo = TableRepo:new(mySQLRepo)
end)