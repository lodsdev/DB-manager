local TableRepo = {}

function TableRepo:new(sqlRepo)
    local instance = {}

    instance.sqlRepo = sqlRepo
    
    setmetatable(instance, {__index = self})
    instance:init()
    
    return instance
end

function TableRepo:init()
    if (not self.datas) then
        self.datas = self.sqlRepo:findAll()
    end
    return self.datas
end

function TableRepo:create(data)
    if (self.datas) then
        self.datas[#self.datas+1] = data
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

function TableRepoClass()
    return TableRepo
end