local RepoService = {}

function RepoService:new(sqlRepo, tableRepo)
    local instance = {}

    instance.sqlRepo = sqlRepo
    instance.tableRepo = tableRepo

    setmetatable(instance, {__index = self})

    return instance
end

function RepoService:create(data)
    self.sqlRepo:create(data)
    self.tableRepo:create(data)
end 

function RepoService:delete(id, value)
    self.sqlRepo:delete(id, value)
    self.tableRepo:delete(id, value)
end

function RepoService:deleteAll()
    self.sqlRepo:deleteAll()
    self.tableRepo:deleteAll()
end

function RepoService:findAll()
    local repo = self.tableRepo:findAll()
    if (not repo) then
        repo = self.sqlRepo:findAll()
    end
    return repo
end

function RepoService:findOne(id, value)
    local repo = self.tableRepo:findOne(id, value)
    if (not repo) then
        repo = self.sqlRepo:findOne(id, value)
    end
    return repo
end

function RepoServiceClass()
    return RepoService
end