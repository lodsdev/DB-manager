local conn
local Users

addEventHandler('onResourceStart', resourceRoot, function()
    conn = DBManager:new({
        dialect = 'sqlite',
        storage = 'database/db.sqlite',
    })
    
    if (not conn:getConnection()) then
        error('DBManager: Connection failed', 2)
    end

    outputDebugString('DBManager: Connection successful')
end)

addCommandHandler('createTable', function(player, cmd)
    Users = conn:define('users', {
        id = {
            type = DBManager.INTEGER,
            primaryKey = true,
            autoIncrement = true,
            allowNull = true,
        },
        name = {
            type = DBManager.STRING(32),
            allowNull = false,
            defaultValue = "LODS"
        },
        age = DBManager.INTEGER
    })
end)