addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManagerClass("sqlite", 'database/db.sqlite')
    local myTbl = TableClass(db:getDB(), 'tests')

    local sql = SQLRepoClass(db, myTbl)
    local repo = TableRepoClass(sql)
    local service = RepoServiceClass(sql, repo)

    local allResults = service:create({4, "'Michael'", 20})
end)