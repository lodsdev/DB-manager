dbDatas = {}
local database = DBManager('sqlTest', 'database')


addEventHandler('onResourceStart', resourceRoot,
    function()
        local myTable = database.db:CreateTable('test', 'id INTEGER, name TEXT')
        local myDatas = database.db:TableRepo()
        dbDatas = database.db:findOne('LODS')
        -- iprint(dbDatas)
    end
)