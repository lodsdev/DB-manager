DBManager = {}

function DBManager:new(dbName, directory)
    local instance = {}

    instance.dbName = dbName
    instance.dbConnection = dbConnect('sqlite', directory)

    setmetatable(instance, {
        __index = DBManager
    })
        
    return instance
end

function DBManager:getDB()
    return self.dbConnection
end