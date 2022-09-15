local SQLRepo = {}

function SQLRepo:new(dbManager, tbl)
    local instance = {}

    private[instance] = {}
    private[instance].dbManager = dbManager
    private[instance].tbl = tbl

    setmetatable(instance, {__index = self})
    return instance
end

function SQLRepo:create(dto)
    if (self.dto ~= dto) then
        self.dto = toJSON(dto)
    end

    local tblFormatted = self.dto:sub(5, self.dto:len() - 4)
    local queryString = dbQuery(
        private[self].dbManager:getDB(), 
        'INSERT INTO `' .. private[self].tbl:getTblName() .. '` VALUES (' .. tblFormatted .. ')'
    )

    if (not queryString) then
        return error('Error while inserting data into table ' .. private[self].tbl:getTblName())
    end

    return true
end

function SQLRepo:delete(id, value)
    local queryDelete = dbExec(
        private[self].dbManager:getDB(), 
        'DELETE FROM `' .. private[self].tbl:getTblName() .. '` WHERE `' .. id .. '` = ?',
        value
    )

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. private[self].tbl:getTblName())
    end

    return true
end

function SQLRepo:deleteAll()
    local queryDelete = dbExec(
        private[self].dbManager:getDB(), 
        'DELETE FROM `' .. private[self].tbl:getTblName() .. '`'
    )

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. private[self].tbl:getTblName())
    end

    return true
end

function SQLRepo:update(data, newValue, id, value)
    local queryUpdate = dbExec(
        private[self].dbManager:getDB(), 
        'UPDATE `' .. private[self].tbl:getTblName() .. '` SET ' .. data .. ' = ? WHERE ' .. id .. ' = ?',
        newValue,
        value
    )

    if (not queryUpdate) then
        return error('Error while updating data from table ' .. private[self].tbl:getTblName())
    end

    return true
end

function SQLRepo:findAll()
    return dbPoll(dbQuery(
        private[self].dbManager:getDB(), 
        'SELECT * FROM `' .. private[self].tbl:getTblName() .. '`'
        ), 
        -1
    )
end

function SQLRepo:findOne(id, value)
    return dbPoll(dbQuery(
        private[self].dbManager:getDB(), 
        'SELECT * FROM `' .. private[self].tbl:getTblName() .. '` WHERE `' .. id .. '` = ?',
        value
        ),
        -1
    )
end

function SQLRepoClass(dbManager, tbl)
    return SQLRepo:new(dbManager, tbl)
end