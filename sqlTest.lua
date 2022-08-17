dbDatas = {}
local database = DBManager('sqlTest', 'database')


addEventHandler('onResourceStart', resourceRoot,
    function()
        local myTable = database.db:CreateTable('test', 'id INTEGER, name TEXT')
        local myDatas = database.db:TableRepo()
        dbDatas = database.db:update('name', 'LODS', 'LODEIS')
        -- iprint(dbDatas)
    end
)