dbDatas = {}

addEventHandler('onResourceStart', resourceRoot,
    function()
        local database = DBManager('sqlTest', 'database')
        local myTable = database.db:CreateTable('test', 'id INTEGER, name TEXT')
        local myDatas = database.db:TableRepo()

        dbDatas = database.db:findAll()
        iprint(dbDatas)

        -- database.db:update('name', 'lodex')

        -- iprint(dbDatas)
    end
)