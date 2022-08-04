--[[
MIT License
Copyright (c) 2022 Vítor Ribeiro
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

local PENDING = 'PENDING'
local FULFILLED = 'FULFILLED'
local REJECTED = 'REJECTED'

local function noop() end

local function isCallable(x)
    return type(x) == 'function' or not not (getmetatable(x) and getmetatable(x).__call)
end

local function isThenable(x)
    return type(x) == 'table' and x.after ~= nil
end

axios = {}
local promise = {}

function promise.__tostring(p)
    local __tostring = promise.__tostring
    promise.__tostring = nil
    local str =  string.format('Promise: %s', tostring(p):sub(8))
    promise.__tostring = __tostring
    return str
end

local newPromise
local resolve
local promiseOnFulfilled
local promiseOnRejected

local function isPromise(x)
    if type(x) ~= 'table' then return false end
    local mtSeen = {}
    local mt = getmetatable(x)
    while mt ~= nil and not mtSeen[mt] do
        if mt == promise then
            return true
        end
        mtSeen[mt] = true
        mt = getmetatable(mt)
    end
    return false
end

local function execFulfilled(thenInfo, value)
    local n = thenInfo
    if not isCallable(n.onFulfilled) then
        promiseOnFulfilled(n.promise, value)
    else
        local success, ret = pcall(n.onFulfilled, value)
        if success then
            resolve(n.promise, ret)
        else
            promiseOnRejected(n.promise, ret)
        end
    end
end

local function execRejected(thenInfo, reason)
    local n = thenInfo
    if not isCallable(n.onRejected) then
        promiseOnRejected(n.promise, reason)
    else
        local success, ret = pcall(n.onRejected, reason)
        if success then
            resolve(n.promise, ret)
        else
            promiseOnRejected(n.promise, ret)
        end
    end
end

promiseOnFulfilled = function (p, value)
    if p._state == PENDING then
        p._value = value
        p._reason = nil
        p._state = FULFILLED
    end
    for _,n in ipairs(p.thenInfoList) do
        execFulfilled(n, value)
    end
end

promiseOnRejected = function (p, reason)
    if p._state == PENDING then
        p._value = nil
        p._reason = reason
        p._state = REJECTED
    end
    for _,n in ipairs(p.thenInfoList) do
        execRejected(n, reason)
    end
end


local function resolveThenable(p, x)
    local after = x.after
    if isCallable(after) then
        local isCalled = false
        local function resolvePromise(y)
            if isCalled then return end
            isCalled = true
            resolve(p, y)
        end
        local function rejectPromise(r)
            if isCalled then return end
            isCalled = true
            promiseOnRejected(p, r)
        end
        local success, err = pcall(after, x, resolvePromise, rejectPromise)
        if not success then
            if not isCalled then
                promiseOnRejected(p, err)
            end
        end
    else
        promiseOnFulfilled(p, x)
    end
end

--[[
    define promise resolution procedure
--]]
resolve = function (p, x)
    if p == x then
        promiseOnRejected(p, 'TypeError: Promise resolution procedure got two identical parameters.')
        return
    end
    if isPromise(x) then
        if x._state == PENDING then
            p._state = PENDING
        end
        resolveThenable(p, x)
    elseif isThenable(x) then
        resolveThenable(p, x)
    else
        promiseOnFulfilled(p, x)
    end
end


function promise:new()
    local p = {}
    setmetatable(p, self)
    self.__index = self
    p.thenInfoList = {}
    p._state = PENDING
    p._value = nil
    p._reason = nil

    return p
end

function promise:after(onFulfilled, onRejected)
    local p = newPromise(noop)

    local thenInfo = {
        promise = p,
    }

    if isCallable(onFulfilled) then
        thenInfo.onFulfilled = onFulfilled
    end
    if isCallable(onRejected) then
        thenInfo.onRejected = onRejected
    end


    if self._state == FULFILLED then
        execFulfilled(thenInfo, self._value)
    elseif self._state == REJECTED then
        execRejected(thenInfo, self._reason)
    end

    table.insert(self.thenInfoList, thenInfo)

    return p
end

function promise:catch(onRejected)
    return self:after(nil, onRejected)
end

function promise:finally(func)
    return self:after(
        function ()
            func()
        end,
        function ()
            func()
        end
    )
end

newPromise = function (func)
    local obj = promise:new()
    local isCalled = false
    local function onFulfilled(value)
        if isCalled then return end
        isCalled = true
        promiseOnFulfilled(obj, value)
    end

    local function onRejected(reason)
        if isCalled then return end
        isCalled = true
        promiseOnRejected(obj, reason)
    end

    if isCallable(func) then
        func(onFulfilled, onRejected)
    end
    return obj
end

Promise = {}
setmetatable(Promise, {
    __call = function (_, func)
        return newPromise(func)
    end
})

Promise.new = newPromise

local function newPromiseFromValue(value)
    local p = newPromise(noop)
    p._state = FULFILLED
    p._value = value
    p._reason = nil
    return p
end

function Promise.resolve(value)
    if isPromise(value) then return value end
    if isThenable(value) then
        local after = value.after
        if isCallable(after) then
            return newPromise(function(onFulfilled, onRejected)
                value:after(onFulfilled, onRejected)
            end)
        else
            return newPromise(function(_, onRejected)
                onRejected(string.format('TypeError: after must be a function (a %s value)', type(after)))
            end)
        end
    end
    return newPromiseFromValue(value)
end


function Promise.reject(value)
    return newPromise(function(_, onRejected)
        onRejected(value)
    end)
end

function Promise.race(values)
    assert(type(values) == 'table', string.format('Promise.race needs an table (a %s value)', type(values)))
    assert(next(values) ~= nil, 'No candidates available for racing.')
    return newPromise(function(onFulfilled, onRejected)
        for _, value in pairs(values) do
            Promise.resolve(value):after(onFulfilled, onRejected)
        end
    end)
end

function Promise.all(array)
    assert(type(array) == 'table', string.format('Promise.all needs an array table (a %s value)', type(array)))
    local args = {}
    for i=1, #array do
        args[i] = array[i]
    end

    return newPromise(function (onFulfilled, onRejected)
        if #args == 0 then return onFulfilled({}) end
        local remaining = #args
        local function res(i, val)
            if isPromise(val) then
                if val._state == FULFILLED then
                    return res(i, val._value)
                end
                if val._state == REJECTED then
                    onRejected(val._reason)
                end
                val:after(function (v)
                    res(i, v)
                end, onRejected)
                return
            elseif isThenable(val) then
                local after = val.after
                if isCallable(after) then
                    local p = newPromise(function(r, rj)
                        val:after(r, rj)
                    end)
                    p:after(function (v)
                        res(i, v)
                    end, onRejected)
                    return
                end
            end
            args[i] = val
            remaining = remaining - 1
            if remaining == 0 then
                onFulfilled(args)
            end
        end
        for i=1, #args do
            res(i, args[i])
        end
    end)
end

function Promise.serial(array)
    assert(type(array) == 'table', string.format('Promise.serial needs an array table (a %s value)', type(array)))
    local args = {}
    for i=1, #array do
        args[i] = array[i]
    end

    return newPromise(function (onFulfilled, onRejected)
        if #args == 0 then return onFulfilled({}) end
        local remaining = #args
        local function res(i, val)
            if isPromise(val) then
                if val._state == FULFILLED then
                    return res(i, val._value)
                end
                if val._state == REJECTED then
                    onRejected(val._reason)
                end
                val:after(function (v)
                    res(i, v)
                end, onRejected)
                return
            elseif isThenable(val) then
                local after = val.after
                if isCallable(after) then
                    local p = newPromise(function(r, rj)
                        val:after(r, rj)
                    end)
                    p:after(function (v)
                        res(i, v)
                    end, onRejected)
                    return
                end
            end
            args[i] = val
            remaining = remaining - 1
            if remaining == 0 then
                onFulfilled(args)
            else
                if isCallable(args[i+1]) then
                    res(i+1, newPromise(args[i+1]))
                else
                    res(i+1, args[i+1])
                end
            end
        end
        if isCallable(args[1]) then
            res(1, newPromise(args[1]))
        else
            res(1, args[1])
        end
    end)
end

local statuscode = {
    [200] = true,
    [201] = true,
    [202] = true,
    [203] = true,
    [204] = true,
    [205] = true,
    [206] = true,
    [207] = true,
    [208] = true,
    [226] = true
}

function axios.get(url, head, callback)
    return Promise.new(function (resolve, reject) 
        return fetchRemote(url, { method="GET", headers = head }, function (data, err) 
            if statuscode[err.statusCode] then 
                return resolve(data)
            else
                return reject({head=err, body=data})
            end
        end, source)
    end)
end

function axios.post(url, head, data, cb)
    return Promise.new(function (resolve, reject) 
        if not data then return reject("No data returned") end 
        
        local resJson = toJSON(data)
        resJson = string.sub(resJson, 3, #resJson - 2)

        local heads = {
            ["Content-Type"] = "application/json",
            ["Accept"] = 'application/json',
            head
        }

        for k,v in pairs(head) do 
            heads[""..k..""] = v
        end
       
        local sendOptions = {
            method = 'POST',
            headers = heads,
            postData = resJson,
        }
        return fetchRemote(url, sendOptions, function (data, err) 
            if statuscode[err.statusCode] then 
                return resolve(data)
            else
                return reject({head=err, body=data})
            end
        end, source)
    end)
end