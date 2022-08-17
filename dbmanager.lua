local dbGenerals = {}

function DBManager(dbName, directory)
    if (not directory) then
        directory = 'database'
    end
    
    local dbConnection = dbConnect('sqlite', ''..directory..'/'..dbName..'.db')

    if (not dbConnection) then
        return error(''..getResourceName(getThisResource())..': Failed to connect to database '..dbName..'!')
    end

    local db = {
        dbName = dbName,
        directory = directory,
        dbConnection = dbConnection,
        tables = {}
    }
    
    setmetatable(db, {__index = dbGenerals})

    local function getDB()
        return dbConnection
    end

    return {db = db, getDB = getDB}
end

function dbGenerals:CreateTable(tblName, tableDefinition)
    if (not self.tblName) then
        self.tblName = tblName
    end
    if (not self.tableDefinition) then
        self.tableDefinition = tableDefinition
    end

    local queryCreate = dbExec(self.dbConnection, 'CREATE TABLE IF NOT EXISTS `' .. tblName .. '` (' .. tableDefinition .. ')')

    if (not queryCreate) then
        return error('[' .. getResourceName(getThisResource()) .. ']: Failed to create table ' .. tblName .. '!')
    end
    
    local function delete()
        dbExec(self.dbConnection, 'DROP TABLE '..tblName)
    end

    local function getTblName()
        return tblName
    end

    return {delete = delete, getTblName = getTblName}
end

function dbGenerals:SQLRepo()
    local function create(dto)
        if (not self.dto) then
            self.dto = toJSON(dto)
        end
    
        self.dto = self.dto:sub(5, self.dto:len() - 4)

        local queryInsert = dbExec(self.dbConnection, 'INSERT INTO `' .. self.tblName .. '` VALUES (' .. self.dto .. ')')
        if (not queryInsert) then
            return error('[' .. getResourceName(getThisResource()) .. ']: Failed to insert into table ' .. self.tblName .. '!')
        end
    end

    local function delete(id)
        dbExec(self.dbConnection, 'DELETE FROM `'..self.tblName..'` WHERE '..id..' = '..id)
    end

    local function update(id, value, newValue)
        dbExec(self.dbConnection, 'UPDATE `' .. self.tblName .. '` SET ' .. id .. ' = ' .. newValue .. ' WHERE ' .. id .. ' = ' .. value)
    end

    local function findAll() 
        return dbPoll(dbQuery(self.dbConnection, 'SELECT * FROM `' .. self.tblName .. '`'), -1)
    end

    local function findOne(id, value)
        return dbPoll(dbQuery(self.dbConnection, 'SELECT * FROM `' .. self.tblName .. '` WHERE `' .. id .. '` = ' .. value), -1)
    end

    return {create = create, delete = delete, update = update, findAll = findAll, findOne = findOne}
end

function dbGenerals:TableRepo()
    local datas = {}
    local instance
    
    local function init()
        datas = self:SQLRepo().findAll()
    end

    init()

    local function create(dto)
        datas[#datas + 1] = dto
    end
    
    local function delete(id)
        for _, value in ipairs(datas) do
            if (value[id] == id) then
                table.remove(datas, i)
            end
        end
    end

    local function update(id, value, newValue)
        for _, v in ipairs(datas) do
            if (v[id] == value) then
                v[id] = newValue
            end
        end
    end

    local function findAll()
        return datas
    end

    local function findOne(id, value)
        for _, v in ipairs(datas) do
            if (v[id] == value) then
                return v
            end
        end
    end

    return {init = init, create = create, delete = delete, update = update, findAll = findAll, findOne = findOne, getInstance = getInstance}
end

function dbGenerals:create(dto)
    self:SQLRepo().create(dto)
    self:TableRepo().create(dto)
end

function dbGenerals:delete(id)
    self:SQLRepo().delete(id)
    self:TableRepo().delete(id)
end

function dbGenerals:update(id, value, newValue)
    self:SQLRepo().update(id, value, newValue)
    self:TableRepo().update(id, value, newValue)
end

function dbGenerals:findAll()
    local repo = self:TableRepo().findAll()
    if (not repo) then
        repo = self:SQLRepo().findAll()
    end
    return repo
end

function dbGenerals:findOne(id, value)
    local repo = self:TableRepo().findOne(id, value)
    -- if (not repo) then
    --     repo = self:SQLRepo().findOne(id)
    -- end
    return repo
end