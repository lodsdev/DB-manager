addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManager:new('dbTest', 'assets/database.db')
    local myTable = DBTable:new(db:getDB(), 'myTable')

    myTable:create(
        'id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER'
    )
end)