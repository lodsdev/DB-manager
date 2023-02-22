local Users

addEventHandler('onResourceStart', resourceRoot, function()
    local conn = DBManager:new({
        dialect = 'sqlite',
        storage = 'database/db.sqlite'
        -- host = 'localhost',
        -- port = 3306,
        -- username = 'root',
        -- password = '123456',
        -- database = 'test_db_manager',
    })
    
    if (not conn:getConnection()) then
        error('DBManager: Connection failed', 2)
    end

    Users = conn:define('Users', {
        id = {
            type = DBManager.INTEGER,
            allowNull = false,
            autoIncrement = true,
            primaryKey = true,
        },
        name = {
            type = DBManager.TEXT(),
            allowNull = false,
        }
    })

    Users:sync()
    -- Users:sync()

    outputDebugString('DBManager: Connection successful')
end)

addCommandHandler('createUser', function(player, cmd)
    Users:create({
        name = 'Test'
    })
end)

addCommandHandler('updateUser', function(player, cmd, name)
    Users:update({
        name = name
    }, {
        where = {
            id = 1
        }
    })
end)

addCommandHandler('dropUser', function(player, cmd)
    Users:drop()
end)

addCommandHandler('getAllData', function(player, cmd)
    local datas = Users:findAll()
    iprint(datas)
    -- outputDebugString('Data: ' .. toJSON(data))
end)