local DBTable = {}

function DBTable:new(dbConnection, tableName)
    local instance = {}

    instance.dbConnection = dbConnection
    instance.tableName = tableName

    setmetatable(instance, {
        __index = self
    })

    return instance
end

function DBTable:create(tableDefinition)
    if (not self.tableDefinition) then
        self.tableDefinition = tableDefinition
    end

    local queryCreate = dbExec(
        self.dbConnection, 
        'CREATE TABLE IF NOT EXISTS `' .. self.tableName .. '` (' .. tableDefinition .. ')'
    )

    if (not queryCreate) then
        return error('Error while creating table ' .. self.tableName)
    end

    return true
end

function DBTable:delete()
    local queryDelete = dbExec(
        self.dbConnection, 'DROP TABLE IF EXISTS `' .. self.tableName
    )

    if (not queryDelete) then
        return error('Error while deleting table ' .. self.tableName)
    end

    return true
end

function DBTable:getTblName()
    return self.tableName
end

function DBTableClass()
    return DBTable
end