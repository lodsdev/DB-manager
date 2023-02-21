local Users

addEventHandler('onResourceStart', resourceRoot, function()
    local conn = DBManager:new({
        dialect = 'mysql',
        host = 'localhost',
        port = 3306,
        username = 'root',
        password = '123456',
        database = 'test_db_manager',
    })
    
    if (not conn:getConnection()) then
        error('DBManager: Connection failed', 2)
    end

    Users = conn:define('users', {
        id = {
            type = DBManager.INTEGER,
            allowNull = false,
            autoIncrement = true,
            primaryKey = true,
        },
        name = {
            type = DBManager.STRING(),
            allowNull = false,
        },
        age = {
            type = DBManager.INTEGER,
            allowNull = true,
        },
        cpf = {
            type = DBManager.STRING(),
            allowNull = false,
            unique = true,
        },
        uuid = DBManager.STRING()
    })

    Users:sync()

    outputDebugString('DBManager: Connection successful')
end)

addCommandHandler('updateData', function(player, cmd, name, cpf)
    local userUpdated = Users:update({
        name = name,
        age = 20,
        cpf = cpf,
    }, {
        where = { 
            id = 1 
        },
    })

    iprint(userUpdated)
end)

addCommandHandler('getOneData', function(player, cmd, name)
    local user = Users:findOne({
        where = { name = name },
    })

    iprint(user)
end)

addCommandHandler('createUser', function(player, cmd, name, age, cpf)
    Users:create({
        name = name,
        age = tonumber(age),
        cpf = cpf,
        uuid = DBManager.UUID()
    })
end)

addCommandHandler('destroyUser', function(player, cmd, id)
    Users:destroy({
        truncate = true
    })
end)