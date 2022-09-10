local DBManager = DBManagerClass()
local DBTable = DBTableClass()
local SQLRepo = SQLRepoClass()
local db

addEventHandler('onResourceStart', resourceRoot, function()
    db = DBManager:new({
        host = 'localhost',
        port = 3306,
        username = 'root',
        password = '',
        database = 'test'
    })

    local myTable = DBTable:new(db:getDB(), 'myDatas')
    myTable:create([[
        id INT NOT NULL AUTO_INCREMENT,
        name VARCHAR(255) NOT NULL, 
        PRIMARY KEY (id)
    ]])

    local myRepo = SQLRepo:new(db, myTable)
    iprint(myRepo:findOne('name', 'LODS'))
end)