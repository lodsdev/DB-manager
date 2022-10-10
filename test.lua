addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManagerClass("sqlite", 'database/db.sqlite')
    local myTbl = TableClass(db:getConnection(), 'tests')
    local service = RepoServiceClass(myTbl)

    -- service:create({5, "LODIS", 20})
    service:delete('id', 5)
end)