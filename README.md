# DB Manager Resource for MTA:SA

## About

This is library for easy manipulation of database in MTA:SA, with a clean syntax and optimized. You don't need to worry about using **Queries** several times, this library manipulates a table in **location** to include all data in cache, this allows you not to look for the data directly in the database, but in the cache.

## Getting started
Text about documentation:

- [Documentation]

## Example (using MySQL)

Example of how to use the library, in this example we will create a table for users, and we will perform the following actions:

```lua
-- connect to database (MySQL)
-- "DBManager" is the variable that contains the library 
-- [check the documentation for more information]
local conn = DBManager:new({
    dialect = "mysql",
    host = "localhost",
    port = 3306,
    username = "root",
    password = "123456",
    database = "test_db_manager",
})

-- check if connection is successful
-- "getConnection" is a function that returns a boolean value indicating if the connection was successful 
-- [check the documentation for more information]
if (not conn:getConnection()) then
    error("DBManager: Connection failed", 2)
end

-- create a table for users
-- "define" is a function that creates a table in the database 
-- [check the documentation for more information]
local Users = conn:define("Users", {
    id = {
        type = DBManager.INTEGER,
        allowNull = false,
        autoIncrement = true,
        primaryKey = true,
    },
    name = {
        type = DBManager.TEXT(),
        allowNull = false,
    }
})

-- It's important to sync the local table with the database
-- "sync" is a function that syncs the local table with the database 
-- [check the documentation for more information]
Users:sync()

addCommandHandler("insertUser", function(player, cmd, name)
    -- insert a new user
    Users:create({ name = name })
end)

addCommandHandler("getUsers", function(player, cmd)
    -- get all users
    local users = Users:findAll()

    iprint(users) --[[
        {
            [1] = {
                id = 1,
                name = 'John'
            },
            [2] = {
                id = 2,
                name = 'Jane'
            }
        }
    ]]
end)

addCommandHandler("getUser", function(player, cmd, id)
    -- get a user by id
    local user = Users:findByPk(id)

    iprint(user) --[[
        {
            id = 1,
            name = 'John'
        }
    ]]
end)

addCommandHandler("getUserByName", function(player, cmd, name)
    -- get a user by name
    local user = Users:findOne({
        where = {
            name = name
        }
    })

    iprint(user) --[[
        {
            id = 1,
            name = 'John'
        }
    ]]
end)

addCommandHandler("updateUser", function(player, cmd, id, name)
    -- update a user by id
    Users:update({
        name = name
    }, {
        where = {
            id = id
        }
    })
end)

addCommandHandler("deleteUser", function(player, cmd, id)
    -- delete a user by id
    Users:destroy({
        where = {
            id = id
        }
    })
end)
```

## Example (using SQLite)

```lua
-- connect to database (MySQL)
local conn = DBManager:new({
    dialect = "sqlite",
    storage = "database/db.sqlite"
})
```

## Supporting the project
Did you like DB Manager and would you like to contribute to its growth?

Feel free to create your fork on your profile and contribute PR's to improve the project.

## License

[Click here to see the license.](https://github.com/lodsdev/database-management/blob/main/MIT-LICENSE.txt)

