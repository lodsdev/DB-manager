Class = {}

function Class:new()
    local instance = {}

    setmetatable(instance, {
        __index = Class
    })

    return instance
end