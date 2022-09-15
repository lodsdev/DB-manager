local RepoService = {}

function RepoService:new(sqlRepo, tableRepo)
    local instance = {}

    private[instance] = {}
    private[instance].sqlRepo = sqlRepo
    private[instance].tableRepo = tableRepo

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
    return repo
end

function RepoService:findOne(id, value)
    local repo = private[self].tableRepo:findOne(id, value)
    if (not repo) then
        repo = private[self].sqlRepo:findOne(id, value)
    end
    return repo
end

function RepoServiceClass(sqlRepo, tableRepo)
    return RepoService:new(sqlRepo, tableRepo)
end