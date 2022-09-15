local service

addEventHandler('onResourceStart', resourceRoot, function()
    local myDB = DBManagerClass('sqlite', 'database/file.db')
    local myTable = TableClass(myDB:getDB(), 'users')
    local sqlRepo = SQLRepoClass(myDB, myTable)
    local myRepo = TableRepoClass(sqlRepo)

    myTable:create([[
        name TEXT, 
        pass TEXT
    ]])

    service = RepoServiceClass(sqlRepo, myRepo)

    -- service:
end)

