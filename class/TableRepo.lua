local TableRepo = {}

function TableRepo:new(sqlRepo)
    local instance = {}

    instance.sqlRepo = sqlRepo

    self:init()

    setmetatable(instance, {__index = self})

    return instance
end

function TableRepo:init()
    if (not self.datas) then
        self.datas = self.sqlRepo:findAll()
    end
    return self.datas
end