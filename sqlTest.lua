
addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManager:new('dbTest', 'assets/database.db')
    local myTable = DBTable:new(db:getDB(), 'myTable')

    myTable:create(
        'name TEXT, age INTEGER'
    )

    local myRepo = SQLRepo:new(db, myTable)

    myRepo:create({"LODS", 20})
    myRepo:create({"KRONOS", 20})
    -- myRepo:delete('name', 'John')
end)