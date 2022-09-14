
local myDB

addEventHandler('onResourceStart', resourceRoot, function()
    myDB = DBManagerClass('sqlite', 'database/file.db')
   
    myTable = DBTableClass(myDB:getDB(), 'users')
    myTable:create([[
        id INTEGER PRIMARY KEY AUTOINCREMENT, 
        name TEXT, 
        age INTEGER
    ]])

    sqlRepo = SQLRepoClass(myDB, myTable)
    myRepo = TableRepoClass(sqlRepo)

    -- local service = RepoServiceClass(sqlRepo, myRepo)
end)

