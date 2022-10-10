# DB Manager Resource for MTA:SA

## About

This is library for easy manipulation of database in MTA:SA, with a clean syntax and optimized. You don't need to worry about using **Queries** several times, this library manipulates a table in **location** to include all data in cache, this allows you not to look for the data directly in the database, but in the cache.

## Getting started
## Example (using MySQL)

To get started, first download the file `dbmanager.lua` and put in your resource, you need instantiate the classes in script. To example we will create table for users.

```lua
local db = DBManagerClass("mysql", {
    host = "localhost",
    port = 3306,
    username = "root",
    password = "myPass123",
    database = "users"
})
local myTable = TableClass(db:getConnection(), "myTable")

-- Create table
myTable:create([[
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    age INT NOT NULL,
    PRIMARY KEY (id)
]]
```

To receive data in location, it is necessary instantiate the service class.

```lua
local service = RepoServiceClass(myTable)
```

## Example (using SQLite)

```lua
local db = DBManagerClass("sqlite", "database/file.db")
```

## Model Querying

## Simple INSERT queries
First, a simple example.

```lua
service:create({1, "'LODS'", 20})
```

```sql
INSERT INTO ... VALUES(1, "LODS", 20)
```

## Simple SELECT queries
You can use `findAll()` method to get all data.

```lua
service:findOne("name", "LODS")
```
```sql
SELECT FROM ... WHERE name = "LODS"
```

## Simple DELETE queries
You can use `deleteAll()` method to delete all data.

```lua
service:delete("name", "LODS")
```
```sql
DELETE FROM ... WHERE name = "LODS"
```

## Simple UPDATE queries
```lua
service:update("name", "LODIS", "id", 1)
```
```sql
UPDATE ... SET name = "LODIS" WHERE id = 1
```


## Support

If you have any question, contact me via Discord: **LODS#8109** or send an e-mail **contact@lods.dev**

## License

[Click here to see the license.](https://github.com/lodsdev/database-management/blob/main/MIT-LICENSE.txt)

