# DB Manager Resource for MTA:SA

## About

This is library for easy manipulation of database in MTA:SA, with a clean syntax and optimized. You don't need to worry about using **Queries** several times, this library manipulates a table in **location** to include all data in cache, this allows you not to look for the data directly in the database, but in the cache.

## Getting started
## Example (using MySQL)

To get started, first download the file `dbmanager.lua` and put in your resource, you need instantiate the classes in script. To example we will create table for users.

```lua
-- connect to database (MySQL)
local conn = DBManager:new({
    host = 'localhost',
    port = 3306,
    username = 'root',
    password = '123456',
    database = 'test_db_manager',
})

-- check if connection is successful
if (not conn:getConnection()) then
    error('DBManager: Connection failed', 2)
end

-- create a table for users
local Users = conn:define('Users', {
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
Users:sync()

addCommandHandler('insertUser', function(player, cmd, name)
    -- insert a new user
    Users:create({
        name = name
    })
end)

addCommandHandler('getUsers', function(player, cmd)
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

addCommandHandler('getUser', function(player, cmd, id)
    -- get a user by id
    local user = Users:findByPk(id)

    iprint(user) --[[
        {
            id = 1,
            name = 'John'
        }
    ]]
end)

addCommandHandler('updateUser', function(player, cmd, id, name)
    -- update a user by id
    Users:update({
        name = name
    }, {
        where = {
            id = id
        }
    })
end)

addCommandHandler('deleteUser', function(player, cmd, id)
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
    dialect = 'sqlite',
    storage = 'database/db.sqlite'
})
```

## Documentation



## License

[Click here to see the license.](https://github.com/lodsdev/database-management/blob/main/MIT-LICENSE.txt)

