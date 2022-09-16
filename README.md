# DB Manager Resource for MTA:SA

## About

This is library to easily manipulation of database in MTA:SA, with a clean sintaxe and optimized. You don't need worried about in use **Queries** several times, this library manipulate a table in **location** to include all data in cache, this allows you not to look for the data directly in the database, but in the cache.

## Getting started
## Example (using MySQL)

To get started, you need instantiate the classes. To example we will create table for users.

```lua
local db = DBManagerClass("mysql", {
    host = "localhost",
    port = 3306,
    username = "root",
    password = "myPass123",
    database = "users"
})
local tbl = TableClass(db:getDB(), "myTable")
local sql = SQLRepoClass(db, tbl)
local repo = TableRepoClass(sql)
```

Now, we will create our first table.

```lua
tbl:create([[
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `name` varchar(255) NOT NULL,
    `age` int(11) NOT NULL,
    PRIMARY KEY (`id`)
]]
```

To receive data in location, this necessary instantiate the class of service.

```lua
local service = RepoServiceClass(sql, repo)
```

## Example (using SQLite)

```lua
local db = DBManagerClass("sqlite", "database/file.db")
```

## Model Querying

## Simple INSERT queries
First, a simple example.

```lua
service:create({1, 'LODS', 20})
```

## Simple SELECT queries
You can use `findAll()` method to get all datas.

```lua
service:findOne('name', 'LODS')
```

## Simple DELETE queries
You can use `deleteAll()` method to delete all datas.

```lua
service:delete('name', 'LODS')
```

## Simple UPDATE queries
```lua
service:update('name', 'LODS', 'id', 1)
```

## Documentation

This work is in progress...


## Support

If there is some question, contact via Discord: **LODS#8109** or e-mail **contact@lods.dev**

## License

[Click here to see the license.](https://github.com/lodsdev/database-management/blob/main/MIT-LICENSE.txt)

