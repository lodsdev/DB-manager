local SQLRepo = {}

function SQLRepo:new(dbManager, tbl)
    local instance = {}

    instance.dbManager = dbManager
    instance.tbl = tbl

    setmetatable(instance, { __index = self })
    return instance
end

function SQLRepo:create(dto)
    if (self.dto ~= dto) then
        self.dto = toJSON(dto)
    end
    
    local tblFormatted = self.dto:sub(5, self.dto:len() - 4)
    
    local queryInsert = dbExec(
        self.dbManager:getDB(), 
        'INSERT INTO `' .. self.tbl:getTblName() .. '` VALUES (' .. tblFormatted .. ')'
    )

    if (not queryInsert) then
        return error('Error while inserting data into table ' .. self.tbl:getTblName())
    end

    return true
end

function SQLRepo:delete(id, value)
    local queryDelete = dbExec(
        self.dbManager:getDB(), 
        'DELETE FROM `' .. self.tbl:getTblName() .. '` WHERE `' .. id .. '` = ?',
        value
    )

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. self.tbl:getTblName())
    end

    return true
end

function SQLRepo:deleteAll()
    local queryDelete = dbExec(
        self.dbManager:getDB(), 
        'DELETE FROM `' .. self.tbl:getTblName() .. '`'
    )

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. self.tbl:getTblName())
    end

    return true
end

function SQLRepo:update(data, newValue, id, value)
    local queryUpdate = dbExec(
        self.dbManager:getDB(), 
        'UPDATE `' .. self.tbl:getTblName() .. '` SET ' .. data .. ' = ? WHERE ' .. id .. ' = ?',
        newValue,
        value
    )

    if (not queryUpdate) then
        return error('Error while updating data from table ' .. self.tbl:getTblName())
    end

    return true
end

function SQLRepo:findAll()
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.tbl:getTblName() .. '`'
        ), 
        -1
    )
end

function SQLRepo:findOne(id, value)
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.tbl:getTblName() .. '` WHERE `' .. id .. '` = ?',
        value
        ), 
        -1
    )
end

function SQLRepoClass(dbManager, tbl)
    return SQLRepo:new(dbManager, tbl)
end