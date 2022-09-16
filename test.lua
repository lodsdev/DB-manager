addEventHandler('onResourceStart', resourceRoot, function()
    local db = DBManagerClass("mysql", {
        host = "localhost",
        port = 3306,
        username = "root",
        password = "",
        database = "users"
    })
    local myTbl = TableClass(db:getDB(), 'tests')

    myTbl:create([[
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `name` varchar(255) NOT NULL,
        `age` int(11) NOT NULL,
        PRIMARY KEY (`id`)
    ]])

    local sql = SQLRepoClass(db, myTbl)
    local repo = TableRepoClass(sql)

    local service = RepoServiceClass(sql, repo)
    service:create({1, 'LODS', 20})
end)