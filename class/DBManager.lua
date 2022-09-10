local DBManager = {}

function DBManager:new(...)
    local instance = {}
    local dto = {...}

    if (type(...) ~= 'table') then
        instance.dbConnection = dbConnect(dto[1], dto[2] or 'database/file.db')
    else
        if (not dto[1]) then
            return error('No database connection provided')
        end
        if (not dto[1].host or not dto[1].username or not dto[1].password or not dto[1].database) then
            return error('Invalid database connection provided')
        end
        local host, port, username, password, database = dto[1].host, dto[1].port, dto[1].username, dto[1].password, dto[1].database
        
        instance.dbConnection = dbConnect(
            'mysql',
            'dbname=' .. database ..
            ';host=' .. host ..
            ';port=' .. port ..
            ';charset=utf8',
            username,
            password
        )

        if (not instance.dbConnection) then
            return error('Error while connecting to database')
        end

        outputDebugString('Connected to database')
    end

    setmetatable(instance, {
        __index = self
    })
        
    return instance
end

function DBManager:getDB()
    return self.dbConnection
end

function DBManagerClass()
    return DBManager
end