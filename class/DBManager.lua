local DBManager = {}

function DBManager:new(...)
    local instance = {}
    local typeDatabase, dto = ...

    if (typeDatabase ~= 'sqlite' or typeDatabase ~= 'mysql') then
        return error('Invalid database type', 2)
    end

    if (not typeDatabase or not dto) then
        local output = (not typeDatabase and 'Error, define a type to database') or (not dto and 'Error, define a dto to database')
        return error(output, 2)
    end

    if (dto ~= 'string') then
        if (not dto.host or not dto.port or not dto.username or not dto.password or not dto.database) then
            return error('Invalid database connection provided', 2)
        end
        local host, port, username, password, database = dto.host, dto.port, dto.username, dto.password, dto.database

        instance.dbConnection = dbConnect(
            typeDatabase,
            'dbname=' .. database ..
            ';host=' .. host ..
            ';port=' .. port ..
            ';charset=utf8',
            username,
            password
        )
        
        outputDebugString('Connected to database')
    else
        instance.dbConnection = dbConnect(typeDatabase, dto or 'database/file.db')
        outputDebugString('Connected to database')
    end
    
    if (not instance.dbConnection) then
        return error('Error while connecting to database', 2)
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