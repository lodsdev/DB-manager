addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManagerClass('sqlite', 'database/file.db')
    local myTbl = TableClass(db:getDB(), 'test')

    myTbl:create([[
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL
    ]])

    local sql = SQLRepoClass(db, myTbl)
    local repo = TableRepoClass(sql)

    local service = RepoServiceClass(sql, repo)
    service:create({1, 'LODS', 20})
end)