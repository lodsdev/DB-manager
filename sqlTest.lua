addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManager:new('dbTest', 'assets/database.db')
    local repo = SQLRepo:new(db, 'tableTest')
    
    repo:create({
        id = 1,
        name = 'test'
    })
end)