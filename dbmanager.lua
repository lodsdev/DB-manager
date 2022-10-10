local DBManager = {}
local DBTable = {}
local SQLRepo = {}
local TableRepo = {}
local RepoService = {}

local private = {}
setmetatable(private, {__mode = 'k'})

function DBManager:new(...)
    local instance = {}
    local typeDatabase, dto = ...

    instance.messageConnect = "Connected to database"

    private[instance] = {}

    if ((typeDatabase ~= 'sqlite') and (typeDatabase ~= 'mysql')) then
        return error('Invalid database type', 2)
    end

    if (not typeDatabase or not dto) then
        local output = (not typeDatabase and 'Error, define a type to database') or (not dto and 'Error, define a dto or a directory to database')
        return error(output, 2)
    end

    if (type(dto) == 'table') then
        if (not dto.host or not dto.port or not dto.username or not dto.password or not dto.database) then
            return error('Invalid database connection provided', 2)
        end
        local host, port, username, password, database = dto.host, dto.port, dto.username, dto.password, dto.database

        private[instance].dbConnection = dbConnect(
            typeDatabase,
            'dbname=' .. database ..
            ';host=' .. host ..
            ';port=' .. port ..
            ';charset=utf8',
            username,
            password
        )
    else
        private[instance].dbConnection = dbConnect(typeDatabase, dto or 'database/file.db')
    end

    if (not private[instance].dbConnection) then
        return error('Error while connecting to database', 2)
    end

    outputDebugString(instance.messageConnect, 3)

    setmetatable(instance, {__index = self})
    return instance
end

function DBManager:getConnection()
    return private[self].dbConnection
end



function DBTable:new(dbConnection, tableName)
    local instance = {}
    
    
    private[instance] = {}
    private[instance].dbConnection = dbConnection
    private[instance].tableName = tableName
    
    
    setmetatable(instance, {__index = self})
    
    instance.sql = SQLRepo:new(private[instance].dbConnection, instance)
    instance.repo = TableRepo:new(instance.sql)
    
    return instance
end

function DBTable:create(tableDefinition)
    if (not self.tableDefinition) then
        self.tableDefinition = tableDefinition
    end

    local queryCreate = dbExec(private[self].dbConnection, 'CREATE TABLE IF NOT EXISTS `' .. private[self].tableName .. '` (' .. tableDefinition .. ')')

    if (not queryCreate) then
        return error('Error while creating table ' .. private[self].tableName, 2)
    end

    return true
end

function DBTable:delete()
    local queryDelete = dbExec(private[self].dbConnection, 'DROP TABLE IF EXISTS `' .. private[self].tableName .. '`')

    if (not queryDelete) then
        return error('Error while deleting table ' .. private[self].tableName, 2)
    end

    return true
end

function DBTable:getTblName()
    return private[self].tableName
end




function SQLRepo:new(dbConnection, tbl)
    local instance = {}

    private[instance] = {}
    private[instance].dbConnection = dbConnection
    private[instance].tbl = tbl

    setmetatable(instance, {__index = self})
    return instance
end

function SQLRepo:create(dto)
    if (not self.dto or self.dto ~= dto) then
        self.dto = toJSON(dto)
    end

    local tblFormatted = self.dto:sub(5, self.dto:len() - 4)
    local queryInsert = dbExec(private[self].dbConnection, 'INSERT INTO `' .. private[self].tbl:getTblName() .. '` VALUES (' .. tblFormatted .. ')')

    if (not queryInsert) then
        return error('Error while inserting data into table ' .. private[self].tbl:getTblName(), 2)
    end

    return true
end

function SQLRepo:delete(id, value)
    local queryDelete = dbExec(private[self].dbConnection, 'DELETE FROM `' .. private[self].tbl:getTblName() .. '` WHERE `' .. id .. '` = ?', value)

    if (not queryDelete) then
        return error('Error while deleting data from table ' .. private[self].tbl:getTblName(), 2)
    end

    return true
end

function SQLRepo:deleteAll()
    local queryDeleteAll = dbExec(private[self].dbConnection, 'DELETE FROM `' .. private[self].tbl:getTblName() .. '`')

    if (not queryDeleteAll) then
        return error('Error while deleting data from table ' .. private[self].tbl:getTblName(), 2)
    end

    return true
end

function SQLRepo:update(data, newValue, id, value)
    local queryUpdate = dbExec(
        private[self].dbConnection, 
        'UPDATE `' .. private[self].tbl:getTblName() .. '` SET ' .. data .. ' = ? WHERE ' .. id .. ' = ?',
        newValue,
        value
    )

    if (not queryUpdate) then
        return error('Error while updating data from table ' .. private[self].tbl:getTblName(), 2)
    end

    return true
end

function SQLRepo:findAll()
    return dbPoll(dbQuery(private[self].dbConnection, 'SELECT * FROM `' .. private[self].tbl:getTblName() .. '`'), -1)
end

function SQLRepo:findOne(id, value)
    return dbPoll(dbQuery(
        private[self].dbConnection,
        'SELECT * FROM `' .. private[self].tbl:getTblName() .. '` WHERE `' .. id .. '` = ?',
        value
        ),
        -1
    )
end



function TableRepo:new(sqlRepo)
    local instance = {}

    private[instance] = {}
    private[instance].sqlRepo = sqlRepo

    setmetatable(instance, {__index = self})
    instance:init()
    return instance
end

function TableRepo:init()
    if (not self.datas) then
        self.datas = private[self].sqlRepo:findAll()
    end
    return self.datas
end

function TableRepo:create(data)
    if (self.datas) then
        self.datas[#self.datas + 1] = data
        return true
    end
    return false
end

function TableRepo:delete(id, value)
    if (self.datas) then
        for i, atb in ipairs(self.datas) do
            if (atb[id] and atb[id] == value) then
                table.remove(self.datas, i)
                return true
            end
        end
    end
    return false
end

function TableRepo:deleteAll()
    if (self.datas) then
        self.datas = {}
        return true
    end
    return false
end

function TableRepo:update(data, newValue, id, value)
    for _, atb in ipairs(self.datas) do
        if (not atb[id] or not atb[data]) then
            return
        end
        if (atb[id] == value and atb[data] ~= newValue) then
            atb[data] = newValue
            return true
        end
    end
    return false
end

function TableRepo:findAll()
    if (self.datas) then
        return self.datas
    end
    return false
end

function TableRepo:findOne(id, value)
    if (self.datas) then
        for __, atb in ipairs(self.datas) do
            if (atb[id] and atb[id] == value) then
                return atb
            end
        end
    end
    return false
end




function RepoService:new(tbl)
    local instance = {}

    private[instance] = {}
    private[instance].sqlRepo = tbl.sql
    private[instance].tableRepo = tbl.repo

    setmetatable(instance, {__index = self})
    return instance
end

function RepoService:create(data)
    private[self].sqlRepo:create(data)
    private[self].tableRepo:create(data)
end

function RepoService:delete(id, value)
    private[self].sqlRepo:delete(id, value)
    private[self].tableRepo:delete(id, value)
end

function RepoService:deleteAll()
    private[self].sqlRepo:deleteAll()
    private[self].tableRepo:deleteAll()
end

function RepoService:update(data, newValue, id, value)
    private[self].sqlRepo:update(data, newValue, id, value)
    private[self].tableRepo:update(data, newValue, id, value)
end

function RepoService:findAll()
    local repo = private[self].tableRepo:findAll()
    if (not repo) then
        repo = private[self].sqlRepo:findAll()
    end
end

function RepoService:findOne(id, value)
    local repo = private[self].tableRepo:findOne(id, value)
    if (not repo) then
        repo = private[self].sqlRepo:findOne(id, value)
    end
    return repo
end




--[[ Functions to manage database ]]--

function DBManagerClass(...)
    return DBManager:new(...)
end

function TableClass(dbConnection, tableName)
    return DBTable:new(dbConnection, tableName)
end

function SQLRepoClass(dbManager, tbl)
    return SQLRepo:new(dbManager, tbl)
end

function TableRepoClass(sqlRepo)
    return TableRepo:new(sqlRepo)
end

function RepoServiceClass(tbl)
    return RepoService:new(tbl)
end
