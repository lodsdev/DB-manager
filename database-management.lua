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
        dbConnection = dbConnection
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

    local queryCreate = dbExec(self.dbConnection, 'CREATE TABLE IF NOT EXISTS '..tblName..' ('..tableDefinition..')')
    if (not queryCreate) then
        return error(''..getResourceName(getThisResource())..': Failed to create table '..tblName..'!')
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

        local queryInsert = dbExec(self.dbConnection, 'INSERT INTO '..self.tblName..' VALUES ('..self.dto..')')
        if (not queryInsert) then
            return error(''..getResourceName(getThisResource())..': Failed to insert into table '..self.tblName..'!')
        end
    end

    local function delete(id)
        dbExec(self.dbConnection, 'DELETE FROM '..self.tblName..' WHERE '..id..' = '..id)
    end

    local function update(id, valueDTO)
        dbExec(self.dbConnection, 'UPDATE '..self.tblName..' SET '..id..' = ? WHERE '..id..' = '..id, valueDTO)
    end

    local function findAll()
        return Promise.new(function(resolve, reject)
            dbQuery(function(qh)
                local result = dbPoll(qh, 0)
                if (not (#result > 0)) then
                    return reject('No results found!')
                end
                return resolve(result)
            end, {}, self.dbConnection, 'SELECT * FROM '..self.tblName)
        end)
    end

    local function findOne(id, callback)
        dbQuery(function(qh)
            local result = dbPoll(qh, 0)
            if (not (#result > 0)) then
                return {}
            end
            callback(result)
        end, {}, this.dbConnection, 'SELECT * FROM '..self.tblName..' WHERE '..id..' = '..id)
    end

    return {create = create, delete = delete, update = update, findAll = findAll, findOne = findOne}
end

function dbGenerals:TableRepo()
    datas = {}

    local function init()
        return Promise.new(function(resolve, reject)
            self:SQLRepo().findAll()
            :after(function(data)
                datas = data
            end)
            :catch(function(err)
                return error(err, 2)
            end)
        end)
        :after(function(data)
            -- iprint(data)
        end)
        :catch(function(err)
            error(err, 2)
        end)
        :finally(function ()
           print('all done')
        end)
    end
    
    init()

    local function create(dto)
        datas[table.maxn(datas) + 1] = dto
    end

    local function delete(id)
        for _, value in ipairs(datas) do
            if (value[id] == id) then
                table.remove(datas, i)
            end
        end
    end

    local function update(id, dto)
        for _, value in ipairs(datas) do
            if (value[id] == id) then
                id = dto
            end
        end
    end

    local function findAll()
        return datas
    end

    local function findOne(id)
        for _, value in ipairs(datas) do
            if (value[id] == id) then
                return value
            end
        end
    end

    return {init = init, create = create, delete = delete, update = update, findAll = findAll, findOne = findOne}
end

function dbGenerals:create(dto)
    self:SQLRepo().create(dto)
    self:TableRepo().create(dto)
end

function dbGenerals:delete(id)
    self:SQLRepo().delete(id)
    self:TableRepo().delete(id)
end

function dbGenerals:update(id, dto)
    self:SQLRepo().update(id, dto)
    self:TableRepo().update(id, dto)
end

function dbGenerals:findAll()
    local repo
    repo = self:TableRepo().findAll()
    -- if (not repo) then
    --     local data = self:SQLRepo().findAll(function(res)
    --         repo = res
    --     end)
    -- end
    return repo
end

function dbGenerals:findOne(id)
    local repo
    local data = self:TableRepo().findOne(id, function(res)
        repo = res
    end)
    if (not repo) then
        local data = self:SQLRepo().findOne(id, function(res)
            repo = res
        end)
    end
    return repo
end