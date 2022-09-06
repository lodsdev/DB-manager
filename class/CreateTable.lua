DBTable = {}

function DBTable:new(dbConnection, tableName)
    local instance = {}

    instance.dbConnection = dbConnection
    instance.tableName = tableName

    setmetatable(instance, {
        __index = DBTable
    })

    return instance
end

function DBTable:create(tableDefinition)
    dbExec(
        self.dbConnection, 
        'CREATE TABLE IF NOT EXISTS ' .. self.tableName .. ' (' .. tableDefinition .. ')'
    )
end

function DBTable:delete()
    dbExec(
        self.dbConnection, 'DROP TABLE IF EXISTS ' .. self.tableName
    )
end

function DBTable:getTblName()
    return self.tableName
end