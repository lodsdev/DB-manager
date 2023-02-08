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

local function isBoolean(bool)
    return type(bool) == 'boolean'
end

local function getTblSize(tbl)
    local length = 0
    for _ in pairs(tbl) do
        length = length + 1
    end
    return length
end

local function convertTableFromPairsToIpairs(tbl)
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

DBManager = {
    STRING = function(length)
        if (length) then
            return 'VARCHAR(' .. length .. ')'
        else
            return 'VARCHAR(255)'
        end
    end,
    BINARY = 'VARCHAR BINARY',
    TEXT = function(t)
        if (t == 'tiny') then
            return 'TINYTEXT'
        else
            return 'TEXT'
        end
    end,
    BOOLEAN = 'BOOLEAN',
    INTEGER = 'INTEGER',
    BIGINT = function(length)
        if (length) then
            return 'BIGINT(' .. length .. ')'
        else
            return 'BIGINT'
        end
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

local crud = {
    create = function(self, data)
        local query = 'INSERT INTO ' .. self.tableName .. ' ('
        local values = ' VALUES ('
        local i = 0

        for key, value in pairs(data) do
            if (i > 0) then
                query = query .. ', '
                values = values .. ', '
            end

            query = query .. key
            values = values .. '?'

            i = i + 1
        end

        query = query .. ')' .. values .. ')'

        
        local queryString = dbPrepareString(self.db:getConnection(), query)
        if (not queryString) then
            return false
        end

        local query = dbQuery(self.db:getConnection(), queryString)
        if (not query) then
            return false
        end

        return true
    end,
}

local private = {}
setmetatable(private, {__mode = 'k'})

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

function DBManager:define(tableName, model)
    local instance = {}

    instance.model = model
    instance.tableName = tableName
    instance.db = self
    instance.dataTypes = {}

    instance.queryDefine = "CREATE TABLE IF NOT EXISTS `" .. instance.tableName .. "` ("
    instance.primaryKey = ""

    local i = 0

    for key, constraints in pairs(instance.model) do
        if (i > 0) then
            instance.queryDefine = instance.queryDefine .. ", "
        end

        instance.queryDefine = instance.queryDefine .. "`" .. key .. "` "

        if (isTable(constraints)) then
            local constraintsArray = {}

            for constraintKey, constraintValue in pairs(constraints) do
                local constraintString = ""
                if (constraintKey == "type") then
                    instance.dataTypes[key] = constraintValue
                    constraintString = constraintValue
                else
                    if (instance.primaryKey ~= "" and constraintKey == "primaryKey") then
                        instance.primaryKey = key
                    elseif (constraintKey == "primaryKey" and instance.primaryKey ~= "") then
                        error("DBManager: Only one primary key is allowed", 2)
                    end

                    -- if (CONSTRAINTS_DATA[constraintKey] and constraintKey ~= "primaryKey") then
                    --     if (isBoolean(constraintValue)) then
                    --         constraintString = CONSTRAINTS_DATA[constraintKey]
                    --     else
                    --         constraintString = CONSTRAINTS_DATA[constraintKey] .. " " .. constraintValue
                    --     end
                    -- end
                end
                
                if (constraintString ~= "") then
                    constraintsArray[#constraintsArray+1] = constraintString
                end
            end

            if (constraints["allowNull"] and constraints["allowNull"] == false) then
                constraintString = constraintString .. " NOT NULL "
            end

            if (constraints["defaultValue"]) then
                constraintString = CONSTRAINTS_DATA["default"] .. " " .. constraints["defaultValue"]
            end

            instance.queryDefine = instance.queryDefine .. table.concat(constraintsArray, " ")
        else
            instance.dataTypes[key] = constraints
            instance.queryDefine = instance.queryDefine .. constraints .. " "
        end

        i = i + 1
    end

    if (instance.primaryKey ~= "") then
        instance.queryDefine = instance.queryDefine .. ", PRIMARY KEY (`" .. instance.primaryKey .. "`)"
    end

    instance.queryDefine = instance.queryDefine .. ")"

    iprint(instance.queryDefine)
    -- local prepareteQueryDefine = dbPrepareString(instance.db:getConnection(), instance.queryDefine)
    -- if (not prepareteQueryDefine) then
    --     error("DBManager: Error preparing query define", 2)
    -- end

    -- local queryDefine = dbExec(instance.db:getConnection(), prepareteQueryDefine)
    -- if (not queryDefine) then
    --     error("DBManager: Error executing query define", 2)
    -- end

    setmetatable(instance, { __index = crud })
    return instance
end