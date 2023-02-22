--[[
    Library: DB Manager
    Author: https://github.com/lodsdev
    Version: 2.0
    
    MIT License
    Copyright (c) 2012-2022 Scott Chacon and others
    Permission is hereby granted, free of charge, to any person obtaining
    a copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:
    The above copyright notice and this permission notice shall be
    included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
    EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
    NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
    LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
    OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
    WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

local cacheUUID = {}
local function generateUUID()
    local function hex(num)
        local hexstr = '0123456789abcdef'
        local s = ''
        while (num > 0) do
            local mod = math.fmod(num, 16)
            s = string.sub(hexstr, mod+1, mod+1) .. s
            num = math.floor(num / 16)
        end
        if (s == '') then s = '0' end
        return s
    end

    local function pad(str, len, char)
        if (char == nil) then char = ' ' end
        return string.rep(char, len - #str) .. str
    end

    local function create()
        math.randomseed(os.time())
        math.random() 
        math.random() 
        math.random()
        local id0 = hex(math.random(0, 0xffff) + 0x10000)
        local id1 = hex(math.random(0, 0xffff) + 0x10000)
        local id2 = hex(math.random(0, 0xffff) + 0x10000)
        local id3 = hex(math.random(0, 0xffff) + 0x10000)
        local id4 = hex(math.random(0, 0xffff) + 0x10000)
        local id5 = hex(math.random(0, 0xffff) + 0x10000)
        local id6 = hex(math.random(0, 0xffff) + 0x10000)
        local id7 = hex(math.random(0, 0xffff) + 0x10000)
        return id0 .. id1 .. '-' .. id2 .. '-' .. id3 .. '-' .. id4 .. '-' .. id5 .. id6 .. id7
    end

    local uuid = create()
    while (cacheUUID[uuid]) do
        uuid = create()
    end

    cacheUUID[uuid] = true
    return uuid
end

local function isTable(tbl)
    return type(tbl) == 'table'
end

local function isString(str)
    return type(str) == 'string'
end

local function isNumber(num)
    return type(num) == 'number'
end

local function isBoolean(bool)
    return type(bool) == 'boolean'
end

local function isNil(nilValue)
    return type(nilValue) == 'nil'
end

local function getTblSize(tbl)
    local length = 0
    for _ in pairs(tbl) do
        length = length + 1
    end
    return length
end

local function pairsToIpairs(tbl)
    local newTbl = {}
    for k, v in pairs(tbl) do
        newTbl[#newTbl+1] = { k, v }
    end
    return newTbl
end

local function tblReverse(tbl, callback)
    local newTbl = {}
    for i = #tbl, 1, -1 do
        newTbl[#newTbl+1] = tbl[i]

        if (callback) then
            callback(tbl[i], i)
        end
    end
    return newTbl
end

local function async(f, callback, ...)
    local asyncCoroutine = coroutine.create(f)
    local function step(...)
        if (coroutine.status(asyncCoroutine) == 'dead') then
            if (callback) then 
                callback(...) 
            end
        else
            local success, result = coroutine.resume(asyncCoroutine, ...)
            if (success) then
                step(result)
            else
                error(result, 2)
            end
        end
    end
    step(...)
end

local function tblFilter(tbl, callback)
    if (not tbl or not callback) then return nil end
    for k, v in pairs(tbl) do
        local exec = callback(k, v)
        if (exec) then
            return k, v
        end
    end
end

local function tblFind(tbl, value)
    if (not tbl or not value) then return nil end
    for k, v in pairs(tbl) do
        if (v == value) then
            return k, v
        end
    end
end

local function prepareAndExecQuery(db, query)
    local queryString = dbPrepareString(db, query)
    if (not queryString) then
        return false
    end
    local queryExec = dbExec(db, queryString)
    if (not queryExec) then
        return false
    end
    return true
end

local function addZeroForLessThan10(number)
    if(number < 10) then
        return 0 .. number
    else
        return number
    end
end

local function generateDateTime()
    local dateTimeTable = os.date('*t')
    local dateTime = dateTimeTable.year .. addZeroForLessThan10(dateTimeTable.month) .. 
    addZeroForLessThan10(dateTimeTable.day) .. addZeroForLessThan10(dateTimeTable.hour) .. addZeroForLessThan10(dateTimeTable.min) .. addZeroForLessThan10(dateTimeTable.sec)
    return dateTime
end

local CONSTRAINTS_DATA = {
    allowNull = 'NOT NULL',
    unique = 'UNIQUE',
    default = 'DEFAULT',
    check = 'CHECK',
    primaryKey = 'PRIMARY KEY',
    foreingKey = 'FOREIGN KEY',
    autoIncrement = 'AUTO_INCREMENT',
    references = 'REFERENCES',
    onDelete = 'ON DELETE',
    onUpdate = 'ON UPDATE',
    comment = 'COMMENT',
    defaultValue = 'DEFAULT',
}

local CONSTRAINT_ORDER = {
    "type",
    "autoIncrement",
    "allowNull",
    "unique",
    "defaultValue",
    "check",
    "references",
    "onDelete",
    "onUpdate",
    "comment",
    "primaryKey",
    "foreignKey"
}

local function addConstraintToQuery(query, key, value)
    local constraintOrderIndex = 1
    local addedConstraint = false
    while (constraintOrderIndex <= #CONSTRAINT_ORDER) do
        local constraint = CONSTRAINT_ORDER[constraintOrderIndex]
        if (constraint ~= 'type') then
            if (constraint == 'allowNull' and value[constraint] == false) then
                query = query .. " " .. CONSTRAINTS_DATA[constraint]
            elseif (constraint ~= 'primaryKey' and constraint ~= 'allowNull' and value[constraint]) then
                if (isBoolean(value[constraint])) then
                    query = query .. " " .. CONSTRAINTS_DATA[constraint]
                else
                    query = query .. " " .. CONSTRAINTS_DATA[constraint] .. " " .. value[constraint]
                end
            end
            addedConstraint = true
        end
        constraintOrderIndex = constraintOrderIndex + 1
    end
    return query
end

local DEBUG_RUNNING_DEFAULT = 'DBManager RUNNING (Default): '

local crud = {
    sync = function(self)
        return async(function()
            local exec = prepareAndExecQuery(self.db:getConnection(), self.queryDefine)
            if (not exec) then
                error('DBManager: Error in query', 2)
            end
            return exec
        end, function()
            local valuesInDB = self.valuesInDB
            local strValues = ''

            for key, value in ipairs(valuesInDB) do
                if (key > 1) then
                    strValues = strValues .. ', '
                end
                strValues = strValues .. '`' .. value .. '`'
            end
            
            local querySelect = 'SELECT ' .. strValues .. ' FROM `' .. self.tableName .. '` AS `' .. self.tableName .. '`'
            local prepareQuery = dbPrepareString(self.db:getConnection(), querySelect)
            if (not prepareQuery) then
                return false
            end
            
            local result, numAffectedRows, lastInsertId  = dbPoll(dbQuery(self.db:getConnection(), prepareQuery), -1)
    
            self.datas = result
            outputDebugString(DEBUG_RUNNING_DEFAULT .. querySelect)

            return result, numAffectedRows, lastInsertId
        end)
    end,

    create = function(self, data)
        local query = 'INSERT INTO `' .. self.tableName .. '` ('
        local values = ' VALUES ('
        local i = 0

        if (self.primaryKey) then
            query = query .. "`" .. self.primaryKey .. "`, "
            values = values .. "" .. #self.datas + 1 .. ", "
        end

        for key, value in pairs(data) do
            if (i > 0) then
                query = query .. ', '
                values = values .. ', '
            end

            query = query .. "`" .. key .. "`"

            if (isString(value)) then
                value = "'" .. value .. "'"
            elseif (isBoolean(value)) then
                value = (value) and 1 or 0
            elseif (isTable(value)) then
                value = "'" .. toJSON(value) .. "'"
            elseif (isNil(value)) then
                value = 'NULL'
            end

            values = values .. value
            i = i + 1
        end

        query = query .. ')' .. values .. ')'

        local exec = prepareAndExecQuery(self.db:getConnection(), query)
        if (not exec) then
            error('DBManager: Error in query, can\'t create data', 2)
        end

        self.datas[#self.datas+1] = data

        outputDebugString('DB Manager RUNNING: ' .. query)
        return data
    end,

    select = function(self, whereClauses, attributes, justOne)
        if (not whereClauses or not isTable(whereClauses)) then
            error('DBManager: Invalid whereClauses (select)', 2)
        end

        local results = {}
        local rows = self.datas
        local valuesInDB = self.valuesInDB

        if (whereClauses and getTblSize(whereClauses) > 0) then
            for _, row in ipairs(rows) do
                local valid = true
                for key, value in pairs(whereClauses) do
                    if (not tblFind(valuesInDB, key)) then
                        error('DBManager: Invalid attribute (select)', 2)
                    end
                    if (row[key] ~= value) then
                        valid = false
                        break
                    end
                end
                if (valid) then
                    results[#results+1] = row
                    if (justOne) then
                        break
                    end
                end
            end
        else
            results = rows
        end

        if (attributes and getTblSize(attributes) > 0) then
            local attributeList = table.concat(attributes, ', ')
            local resultsWithAttributes = {}

            for _, row in ipairs(results) do
                local result = {}
                for _, attribute in ipairs(attributes) do
                    if (not tblFind(valuesInDB, attribute)) then
                        error('DBManager: Invalid attribute (select)', 2)
                    end
                    result[attribute] = row[attribute]
                end
                resultsWithAttributes[#resultsWithAttributes+1] = result
            end

            results = resultsWithAttributes
        end
        return results
    end,

    findAll = function(self, options)
        local whereClauses = options and options.where or {}
        local attributes = options and options.attributes or {}
        local orderBy = options and options.orderBy or nil
        local limit = options and options.limit or nil
        local offset = options and options.offset or 0
        local order = options and options.order or 'ASC'

        local results = self:select(whereClauses, attributes)

        if (not results) then
            error('DBManager: Invalid results (findAll), please open the issue in GitHub', 2)
        end

        if (orderBy) then
            local orderType = (order == 'ASC') and 1 or -1

            table.sort(results, function(a, b)
                if (orderType == 1) then
                    return a[orderBy] < b[orderBy]
                else
                    return a[orderBy] > b[orderBy]
                end
            end)
        end

        if (limit) then
            local resultsWithLimit = {}
            for i, result in ipairs(results) do
                if (i > offset + limit) then break end
                if (i > offset) then
                    resultsWithLimit[#resultsWithLimit + 1] = result
                end
            end
            results = resultsWithLimit
        end
        return results
    end,

    findOne = function(self, options)
        if (not options) then
            error('DBManager: Invalid options (findOne)', 2)
        end

        local whereClauses = options.where or {}
        local attributes = options.attributes or {}

        local results = self:select(whereClauses, attributes, true)

        if (not results) then
            error('DBManager: Invalid results (findOne), please open the issue in GitHub', 2)
        end
        return results
    end,

    findByPk = function(self, pk, options)
        if (not self.primaryKey) then
            error('DBManager: Invalid primaryKey (findByPk)', 2)
        end

        if (not pk) then
            error('DBManager: Invalid pk (findByPk)', 2)
        end

        local whereClauses = options and options.where or {}
        local attributes = options and options.attributes or {}

        whereClauses[self.primaryKey] = pk

        local results = self:select(whereClauses, attributes, true)

        if (not results) then
            error('DBManager: Invalid results (findByPk), please open the issue in GitHub', 2)
        end
        return results
    end,
    
    update = function(self, data, options)
        if (not options or not isTable(options)) then
            error('DBManager: Invalid options (update)', 2)
        end

        local whereClauses = options.where or {}
        local query = 'UPDATE `' .. self.tableName .. '` SET '
        local i = 0

        for key, value in pairs(data) do
            if (i > 0) then
                query = query .. ', '
            end

            if (isString(value)) then
                value = "'" .. value .. "'"
            elseif (isBoolean(value)) then
                value = (value) and 1 or 0
            elseif (isTable(value)) then
                value = "'" .. toJSON(value) .. "'"
            elseif (isNil(value)) then
                value = 'NULL'
            end

            query = query .. "`" .. key .. "` = " .. value
            i = i + 1
        end

        if (self.db.data.dialect == 'sqlite') then
            query = query .. ', `updated_at` = CURRENT_TIMESTAMP'
        end

        query = query .. ' WHERE '

        i = 0
        for key, value in pairs(whereClauses) do
            if (i > 0) then
                query = query .. ' AND '
            end

            query = query .. "`" .. key .. "` = " .. value
            i = i + 1
        end

        local exec = prepareAndExecQuery(self.db:getConnection(), query)
        if (not exec) then
            error('DBManager: ERROR when updating data, please open the issue in GitHub', 2)
        end

        local rows = self.datas
        local valuesInDB = self.valuesInDB

        for _, row in ipairs(rows) do
            local valid = true
            for key, value in pairs(whereClauses) do
                if (not tblFind(valuesInDB, key)) then
                    error('DBManager: Invalid attribute (update)', 2)
                end
                if (row[key] ~= value) then
                    valid = false
                    break
                end
            end
            if (valid) then
                for key, value in pairs(data) do
                    if (not tblFind(valuesInDB, key)) then
                        error('DBManager: Invalid attribute (update)', 2)
                    end
                    row[key] = value
                end
            end
        end

        return true
    end,

    destroy = function(self, options)
        if (not options or not isTable(options)) then
            error('DBManager: Invalid options (destroy)', 2)
        end

        local whereClauses = options.where or {}
        local truncate = options.truncate or false
        local query = 'DELETE FROM `' .. self.tableName .. '` WHERE '

        local i = 0
        for key, value in pairs(whereClauses) do
            if (i > 0) then
                query = query .. ' AND '
            end

            query = query .. "`" .. key .. "` = " .. value

            i = i + 1
        end

        if (truncate) then
            query = 'TRUNCATE TABLE `' .. self.tableName .. '`'
        end

        local exec = prepareAndExecQuery(self.db:getConnection(), query)
        if (not exec) then
            error('DBManager: ERROR when deleting data, please open the issue in GitHub', 2)
        end

        local rows = self.datas
        local valuesInDB = self.valuesInDB

        for i, row in ipairs(rows) do
            local valid = true
            for key, value in pairs(whereClauses) do
                if (not tblFind(valuesInDB, key)) then
                    error('DBManager: Invalid attribute (destroy)', 2)
                end
                if (row[key] ~= value) then
                    valid = false
                    break
                end
            end
            if (valid) then
                table.remove(rows, i)
            end
        end

        return true
    end,

    drop = function(self)
        local query = 'DROP TABLE `' .. self.tableName .. '`'
        local exec = prepareAndExecQuery(self.db:getConnection(), query)
        if (not exec) then
            error('DBManager: ERROR when dropping table, please open the issue in GitHub', 2)
        end

        self.datas = {}
        self.db:removeTable(self.tableName)

        return true
    end,

    every = function(self, callback)
        for i, data in ipairs(self.datas) do
            callback(data, i)
        end
    end,
}

local private = {}
setmetatable(private, {__mode = 'k'})

DBManager = {
    STRING = function(length)
        return (length) and 'VARCHAR(' .. length .. ')' or 'VARCHAR(255)'
    end,
    BINARY = 'VARCHAR BINARY',
    TEXT = function(t)
        return (t == 'tiny') and 'TINYTEXT' or 'TEXT'
    end,
    BOOLEAN = 'BOOLEAN',
    INTEGER = 'INTEGER',
    BIGINT = function(length)
        return (length) and 'BIGINT(' .. length .. ')' or 'BIGINT'
    end,
    FLOAT = function(length, decimals)
        if (length and decimals) then
            return 'FLOAT(' .. length .. ', ' .. decimals .. ')'
        else
            return 'FLOAT'
        end
    end,
    DOUBLE = function(length, decimals)
        if (length and decimals) then
            return 'DOUBLE(' .. length .. ', ' .. decimals .. ')'
        else
            return 'DOUBLE'
        end
    end,
    DECIMAL = function(length, decimals)
        if (length and decimals) then
            return 'DECIMAL(' .. length .. ', ' .. decimals .. ')'
        else
            return 'DECIMAL'
        end
    end,
    DATE = 'DATE',
    TIME = 'TIME',
    DATETIME = 'DATETIME',
    DATEONLY = 'DATEONLY',
    UUID = generateUUID,
    NOW = function ()
        return generateDateTime()
    end
}

local allModels = {}

function DBManager:new(data)
    local instance = {}

    if (not data) then
        error('DBManager: Data is required', 2)
    end
    
    instance.data = data
    
    if (instance.data.dialect == 'mysql') then
        instance.data.charset = instance.data.charset or 'utf8'
        instance.data.options = instance.data.options or ''
        instance.CONNECTION = dbConnect(
            instance.data.dialect, 
            'host=' .. instance.data.host .. ';port=' .. instance.data.port .. ';dbname=' .. instance.data.database .. ';charset=' .. instance.data.charset, 
            instance.data.username, 
            instance.data.password,
            instance.data.options
        )
    elseif (data.dialect == 'sqlite') then
        instance.CONNECTION = dbConnect(instance.data.dialect, instance.data.storage)
    end

    setmetatable(instance, { __index = self })
    return instance
end

function DBManager:getConnection()
    return self.CONNECTION
end

function DBManager:query(queryString)
    local preparatedString = dbPrepareString(self:getConnection(), queryString)
    if (not preparatedString) then
        return false
    end

    local query = dbQuery(self:getConnection(), preparatedString)
    if (not query) then
        return false
    end

    local result, numAffectedRows, lastInsertId = dbPoll(query, -1)
    if (not result) then
        return false
    end

    return result, numAffectedRows, lastInsertId 
end

function DBManager:define(tableName, modelDefinition)
    local instance = {}

    instance.modelDefinition = modelDefinition
    instance.tableName = tableName
    instance.db = self
    instance.dataTypes = {}
    instance.primaryKey = ""
    instance.valuesInDB = {}
    instance.datas = {}
    
    local queryDefine = "CREATE TABLE IF NOT EXISTS `" .. instance.tableName .. "` ("

    local i = 0
    for key, value in pairs(modelDefinition) do
        if (i > 0) then
            queryDefine = queryDefine .. ", "
        end
        
        queryDefine = queryDefine .. "`" .. key .. "`"

        if (isTable(value)) then
            if (value.type) then
                instance.dataTypes[key] = value.type
                queryDefine = queryDefine .. " " .. value.type
            end

            if (instance.primaryKey == "" and value.primaryKey) then
                instance.primaryKey = key
            elseif (instance.primaryKey ~= "" and value.primaryKey) then
                error('DBManager: Only one primary key is allowed', 2)
            end

            queryDefine = addConstraintToQuery(queryDefine, key, value)
        else
            instance.dataTypes[key] = value
            queryDefine = queryDefine .. " " .. value
        end

        instance.valuesInDB[#instance.valuesInDB+1] = key
        i = i + 1
    end

    
    if (instance.primaryKey == "") then
        instance.primaryKey = 'id'
        queryDefine = queryDefine .. ", `" .. instance.primaryKey .. "` INTEGER PRIMARY KEY AUTOINCREMENT"
    end
    
    if (instance.db.dialect == 'mysql') then
        queryDefine = queryDefine .. ", `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP"
        queryDefine = queryDefine .. ", `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP"
    else
        queryDefine = queryDefine .. ", `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP"
        queryDefine = queryDefine .. ", `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP"
    end
    
    instance.valuesInDB[#instance.valuesInDB+1] = 'created_at'
    instance.valuesInDB[#instance.valuesInDB+1] = 'updated_at'

    instance.queryDefine = queryDefine .. ", PRIMARY KEY (`" .. instance.primaryKey .. "`))"

    allModels[#allModels+1] = instance
    setmetatable(instance, { __index = crud })
    return instance
end

function DBManager:removeTable(tableName)
    for i, model in ipairs(allModels) do
        if (model.tableName == tableName) then
            table.remove(allModels, i)
        end
    end
end

function DBManager:sync()
    for _, model in ipairs(allModels) do
        model:sync()
    end
end