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

--[[
    model mysql: {
        dialect = 'mysql',
        host = '',
        port = '',
        username = '',
        password = ''
        database = '',

    },
    model sqlite: {
        dialect = 'sqlite',
        storage = 'database/db.sqlite',
    }
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

local function tableReverse(tbl, callback)
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
            if (callback) then callback(...) end
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
                query = query .. " " .. CONSTRAINTS_DATA[constraint]
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
            local prepareQuery = dbPrepareString(self.db:getConnection(), self.queryDefine)
            if (not prepareQuery) then
                error('DBManager: Error in prepare query', 2)
            end
    
            local query = dbExec(self.db:getConnection(), prepareQuery)
            if (not query) then
                error('DBManager: Error in query', 2)
            end
            
            return query
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
            local result, numAffectedRows, lastInsertId  = dbPoll(dbQuery(self.db:getConnection(), querySelect), -1)
            if (not (#result > 0)) then
                return false
            end
    
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
        
        local queryString = dbPrepareString(self.db:getConnection(), query)
        if (not queryString) then
            return false
        end
        
        local queryExec = dbExec(self.db:getConnection(), queryString)
        if (not queryExec) then
            return false
        end

        self.datas[#self.datas+1] = data

        outputDebugString('DB Manager RUNNING: ' .. query)
        return data
    end,

    findAll = function(self, data)
        if (data) then
            assert(data.attributes or data.where, 'DBManager: Invalid data (findAll)')

            if (data.where) then
                local where = data.where
                local rows = self.datas
                local whereClause = {}
                local results = {}
                
                for i, row in ipairs(rows) do
                    local match = true
                    for j, attribute in pairs(where) do
                        if (row[j] ~= attribute) then
                            match = false
                            break
                        end
                        whereClause[#whereClause+1] = '`' .. self.tableName .. '`.`' .. j .. '` = ' .. attribute .. ''
                    end
                    if (match) then
                        results[#results+1] = row
                    end
                end

                outputDebugString(DEBUG_RUNNING_DEFAULT .. 'SELECT * FROM `' .. self.tableName .. '` WHERE ' .. table.concat(whereClause, ', '))
                return results
            else
                local attributes = data.attributes
                local attributeList = table.concat(attributes, ', ')
                local rows = self.datas

                local results = {}
                for _, row in ipairs(rows) do
                    local result = {}
                    for _, attribute in ipairs(attributes) do
                        result[attribute] = row[attribute]
                    end
                    results[#results+1] = result
                end

                outputDebugString(DEBUG_RUNNING_DEFAULT .. 'SELECT ' .. attributeList .. ' FROM `' .. self.tableName .. '`')
                return results
            end
        end
        return self.datas
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
    DATEONLY = 'DATEONLY',
    UUID = generateUUID,
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

function DBManager:define(tableName, model)
    local instance = {}

    instance.model = model
    instance.tableName = tableName
    instance.db = self
    instance.dataTypes = {}
    instance.primaryKey = ""
    instance.valuesInDB = {}
    instance.datas = {}
    
    local queryDefine = "CREATE TABLE IF NOT EXISTS `" .. instance.tableName .. "` ("

    local i = 0
    for key, value in pairs(model) do
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

    instance.queryDefine = queryDefine .. ", PRIMARY KEY (`" .. instance.primaryKey .. "`))"

    setmetatable(instance, { __index = crud })
    return instance
end