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

local function isBoolean(bool)
    return type(bool) == 'boolean'
end

local function isNil(nilValue)
    return type(nilValue) == 'nil'
end

local function isNumber(number)
    return type(number) == 'number'
end

local function isJSON(value)
    return ((isString(value) and value:gmatch('%[%[.+%]%]')) and fromJSON(value) or value)
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

local function tblFind(tbl, value)
    if (not tbl or not value) then return nil end
    for k, v in pairs(tbl) do
        if (v == value) then
            return k, v
        end
    end
end

local function prepareAndExecQuery(db, query, ...)
    local params = { ... }
    local queryString = dbPrepareString(db, query, unpack(params))
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

local function toSQLValue(value)
    if (isNumber(value)) then
        return tostring(value)
    elseif (isBoolean(value)) then
        return value and 1 or 0
    elseif (isTable(value)) then
        return toJSON(value)
    elseif (isNil(value)) then
        return 'NULL'
    else
        return value
    end
end

local function formatTblFromDB(tbl)
    local newTbl = {}
    for k, v in ipairs(tbl) do
        if (not newTbl[k]) then
            newTbl[k] = {}
        end
        for key, value in pairs(v) do
            newTbl[k][key] = isJSON(value)
        end
    end
    return newTbl
end

local CONSTRAINTS_DATA = {
    allowNull = 'NOT NULL',
    unique = 'UNIQUE',
    defaultValue = 'DEFAULT',
    check = 'CHECK',
    primaryKey = 'PRIMARY KEY',
    foreingKey = 'FOREIGN KEY',
    autoIncrement = 'AUTO_INCREMENT',
    references = 'REFERENCES',
    onDelete = 'ON DELETE',
    onUpdate = 'ON UPDATE',
    comment = 'COMMENT',
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
    local constraintsToAdd = {}
    for i = 1, #CONSTRAINT_ORDER do
        local constraint = CONSTRAINT_ORDER[i]
        if (constraint ~= 'type' and value[constraint] ~= nil) then
            if (constraint == 'allowNull' and not value[constraint]) then
                constraintsToAdd[#constraintsToAdd+1] = CONSTRAINTS_DATA[constraint]
            elseif (constraint ~= 'primaryKey' and constraint ~= 'allowNull') then
                local constraintValue = isBoolean(value[constraint]) and '' or ' ' .. value[constraint]
                constraintsToAdd[#constraintsToAdd+1] = CONSTRAINTS_DATA[constraint] .. constraintValue
            end
        end
    end
    return query .. ' ' .. table.concat(constraintsToAdd, ' ')
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
            local strValues = table.concat(valuesInDB, ', ')

            local querySelect = 'SELECT ' .. strValues .. ' FROM `' .. self.tableName .. '` AS `' .. self.tableName .. '`'
            local prepareQuery = dbPrepareString(self.db:getConnection(), querySelect)
            if (not prepareQuery) then
                return false
            end

            local result, numAffectedRows, lastInsertId  = dbPoll(dbQuery(self.db:getConnection(), prepareQuery), -1)
            self.datas = (#result > 0) and formatTblFromDB(result) or {}
            outputDebugString(DEBUG_RUNNING_DEFAULT .. querySelect)

            return result, numAffectedRows, lastInsertId
        end)
    end,

    create = function(self, data)
        local values = {}
        local queryParts = { 'INSERT INTO `', self.tableName, '` (' }
        local dataValues = {}

        if (self.primaryKey) then
            queryParts[#queryParts+1] = '`' .. self.primaryKey .. '`'
            values[#values+1] = '?'
            dataValues[#dataValues+1] = #self.datas + 1
        end

        local i = 0
        for key, value in pairs(data) do
            if (#values > 0) then
                queryParts[#queryParts+1] = ', '
            end

            queryParts[#queryParts+1] = '`'
            queryParts[#queryParts+1] = key
            queryParts[#queryParts+1] = '`'
            values[#values+1] = '?'
            dataValues[#dataValues+1] = toSQLValue(value)

            i = i + 1
        end

        queryParts[#queryParts+1] = ') VALUES (' .. table.concat(values, ', ') .. ')'

        local query = table.concat(queryParts)
        local exec = prepareAndExecQuery(self.db:getConnection(), query, unpack(dataValues))
        if (not exec) then
            error('DBManager: Error in query, can\'t create data', 2)
        end

        self.datas[#self.datas + 1] = data

        outputDebugString('DB Manager RUNNING: ' .. query)
        return data
    end,

    select = function(self, whereClauses, attributes, justOne)
        if (not whereClauses or not isTable(whereClauses)) then
            error('DBManager: Invalid whereClauses (select)', 2)
        end

        local rows = self.datas
        local valuesInDB = self.valuesInDB
        local results = {}
        local resultsWithAttributes = {}

        for _, attribute in ipairs(attributes or {}) do
            if (not tblFind(valuesInDB, attribute)) then
                error('DBManager: Invalid attribute (select)', 2)
            end
        end

        for _, row in pairs(rows) do
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

        if (attributes and (#attributes > 0)) then
            for _, row in ipairs(results) do
                local result = {}
                for _, attribute in ipairs(attributes) do
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
                return orderType * (a[orderBy] < b[orderBy] and -1 or 1) < 0
            end)
        end

        if (limit) then
            for i = #results, 1, -1 do
                if (i <= offset or i > (offset + limit)) then
                    table.remove(results, i)
                end
            end
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
        return results[1]
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
        local queryParts = { 'UPDATE `', self.tableName, '` SET ' }
        local values = {}

        for key, value in pairs(data) do
            if (#values > 0) then
                queryParts[#queryParts+1] = ', '
            end

            queryParts[#queryParts+1] = '`'
            queryParts[#queryParts+1] = key
            queryParts[#queryParts+1] = '` = ?'
            
            values[#values+1] = toSQLValue(value)
        end
        
        if (self.db.data.dialect == 'sqlite') then
            queryParts[#queryParts+1] = ', `updated_at` = CURRENT_TIMESTAMP'
        end

        queryParts[#queryParts+1] = ' WHERE '

        local i = 0
        for key, value in pairs(whereClauses) do
            if (i > 0) then
                queryParts[#queryParts+1] = ' AND '
            end

            queryParts[#queryParts+1] = '`'
            queryParts[#queryParts+1] = key
            queryParts[#queryParts+1] = '` = ?'

            values[#values+1] = toSQLValue(value)

            i = i + 1
        end

        local query = table.concat(queryParts)
        local exec = prepareAndExecQuery(self.db:getConnection(), query, unpack(values))
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
        local queryParts = { 'DELETE FROM `', self.tableName, '` WHERE '}
        local values = {}

        if (truncate) then
            queryParts = { 'TRUNCATE TABLE `', self.tableName, '`' }
        else
            local i = 0
            for key, value in pairs(whereClauses) do
                if (i > 0) then
                    queryParts[#queryParts+1] = ' AND '
                end

                queryParts[#queryParts+1] = '`'
                queryParts[#queryParts+1] = key
                queryParts[#queryParts+1] = '` = ?'
                values[#values+1] = toSQLValue(value)

                i = i + 1
            end
        end

        local query = table.concat(queryParts)
        local exec = prepareAndExecQuery(self.db:getConnection(), query, unpack(values))
        if (not exec) then
            error('DBManager: ERROR when destroying data, please open the issue in GitHub', 2)
        end

        if (not truncate) then
            local valuesInDB = self.valuesInDB
            for i = #self.datas, 1, -1 do
                local row = self.datas[i]
                local valid = true
                for key, value in ipairs(whereClauses) do
                    if (not tblFind(valuesInDB, key)) then
                        error('DBManager: Invalid attribute (destroy)', 2)
                    end
                    if (row[key] ~= value) then
                        valid = false
                        break
                    end
                end
                if (valid) then
                    table.remove(self.datas, i)
                end
            end
        else
            self.datas = {}
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
    BINARY = function(length)
        return (length) and 'BINARY(' .. length .. ')' or 'BINARY'
    end,
    TEXT = function(t)
        return (t == 'tiny') and 'TINYTEXT' or 'TEXT'
    end,
    BOOLEAN = function()
        return 'BOOLEAN'
    end,
    INTEGER = function()
        return 'INTEGER'
    end,
    INT = function(length)
        return (length) and 'INT(' .. length .. ')' or 'INT'
    end,
    BIGINT = function(length)
        return (length) and 'BIGINT(' .. length .. ')' or 'BIGINT'
    end,
    FLOAT = function(length, decimals)
        if (length) then
            return 'FLOAT(' .. length .. ')'
        elseif (length and decimals) then
            return 'FLOAT(' .. length .. ', ' .. decimals .. ')'
        else
            return 'FLOAT'
        end
    end,
    DOUBLE = function(length, decimals)
        if (length) then
            return 'DOUBLE(' .. length .. ')'
        elseif (length and decimals) then
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
    BLOB = function(t)
        return (t == 'tiny') and 'TINYBLOB' or 'BLOB'
    end,
    DATE = function()
        return 'DATE'
    end,
    TIME = function()
        return 'TIME'
    end,
    DATETIME = function()
        return 'DATETIME'
    end,
    DATEONLY = function()
        return 'DATE'
    end,
    NOW = function ()
        return generateDateTime()
    end,
    UUID = generateUUID,

    models = {}
}

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
        instance.CONNECTION = dbConnect(instance.data.dialect, instance.data.storage or 'database.db')
    end

    setmetatable(instance, { __index = self })
    return instance
end

function DBManager:getConnection()
    return self.CONNECTION
end

function DBManager:close()
    local connection = self:getConnection()
    if (isElement(connection)) then
        destroyElement(connection)
        return true
    end
    return false
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
        error('DBManager: No primary key defined', 2)
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

    self.models[tableName] = instance
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
    for _, model in pairs(self.models) do
        model:sync()
    end
end

function DBManager:drop()
    for _, model in pairs(self.models) do
        model:drop()
    end
end