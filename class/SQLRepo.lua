SQLRepo = {}

function SQLRepo:new(dbManager, table)
    local instance = {}

    instance.dbManager = dbManager
    instance.table = table

    setmetatable(instance, {
        __index = SQLRepo
    })

    return instance
end

function SQLRepo:create()
    dbExec(
        self.dbManager:getDB(), 
        'INSERT INTO ' .. self.tableName .. ' (' .. tableDefinition .. ')'
    )
end

function SQLRepo:delete(id)
    dbExec(
        self.dbManager:getDB(), 
        'DELETE FROM `' .. self.tableName .. '` WHERE `' .. id .. '` = ?',
        id
    )
end

function SQLRepo:update(id, data)
    dbExec(
        self.dbManager:getDB(), 
        'UPDATE `' .. self.tableName .. '` SET `' .. data .. '` WHERE `' .. id .. '` = ?',
        id
    )
end

function SQLRepo:findAll()
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.tableName .. '`'
        ), 
        -1
    )
end

function SQLRepo:findOne(id)
    return dbPoll(dbQuery(
        self.dbManager:getDB(), 
        'SELECT * FROM `' .. self.tableName .. '` WHERE `' .. id .. '` = ?',
        id
        ), 
        -1
    )
end