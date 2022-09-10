SQLRepo = {}

function SQLRepo:new(dbManager, table)
    local instance = {}

    instance.dbManager = dbManager
    instance.table = table

    setmetatable(instance, {
        __index = self
    })

    return instance
end

function SQLRepo:create(dto)
    self.dto = toJSON(dto)
    
    local tblFormatted = self.dto:sub(5, self.dto:len() - 4)
    local dbConnection = self.dbManager:getDB()
    
    local queryInsert = dbExec(
        dbConnection, 
        'INSERT INTO `' .. self.table:getTblName() .. '` VALUES (' .. tblFormatted .. ')'
    )

    if (not queryInsert) then
        return error('Error while inserting data into table ' .. self.table:getTblName())
    end

    return true
end

function SQLRepo:delete(id)
    local queryDelete = dbExec(
        self.dbManager:getDB(), 
        'DELETE FROM `' .. self.table.tableName .. '` WHERE `' .. id .. '` = ?',
        id
    )

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. self.table:getTblName())
    end

    return true
end

function SQLRepo:update(id, data)
    local queryUpdate = dbExec(
        self.dbManager:getDB(), 
        'UPDATE `' .. self.table.tableName .. '` SET `' .. data .. '` WHERE `' .. id .. '` = ?',
        id
    )

    if (not queryUpdate) then
        return error('Error while updating data from table ' .. self.table:getTblName())
    end

    return true
end

function SQLRepo:findAll()
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.table.tableName .. '`'
        ), 
        -1
    )
end

function SQLRepo:findOne(id)
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.table.tableName .. '` WHERE `' .. id .. '` = ?',
        id
        ), 
        -1
    )
end