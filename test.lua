local conn
local Users

addEventHandler('onResourceStart', resourceRoot, function()
    conn = DBManager:new({
        dialect = 'sqlite',
        storage = 'database/db.sqlite'
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

    outputDebugString('DBManager: Connection successful')
end)

addCommandHandler('closeConn', function()
    local closed = conn:close()
    iprint(closed)
end)