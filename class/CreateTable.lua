local DBTable = {}

function DBTable:new(dbConnection, tableName)
    local instance = {}

    private[instance] = {}
    private[instance].dbConnection = dbConnection
    private[instance].tableName = tableName

    setmetatable(instance, {__index = self})
    return instance
end

function DBTable:create(tableDefinition)
    if (not self.tableDefinition) then
        self.tableDefinition = tableDefinition
    end

    local queryCreate = dbExec(
        private[self].dbConnection, 
        'CREATE TABLE IF NOT EXISTS `' .. private[self].tableName .. '` (' .. tableDefinition .. ')'
    )

    if (not queryCreate) then
        return error('Error while creating table ' .. private[self].tableName)
    end

    return true
end

function DBTable:delete()
    local queryDelete = dbExec(
        private[self].dbConnection, 'DROP TABLE IF EXISTS `' .. private[self].tableName .. '`'
    )

    if (not queryDelete) then
        return error('Error while deleting table ' .. private[self].tableName)
    end

    return true
end

function DBTable:getTblName()
    return private[self].tableName
end

function TableClass(dbConnection, tableName)
    return DBTable:new(dbConnection, tableName)
end