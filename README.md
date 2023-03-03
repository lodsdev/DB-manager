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
```

Let's create a table for users.
```lua
-- sintaxe
local table = conn:define('table_name', {
    column_name = {
        type = DBManager.INTEGER,
        allowNull = false,
        autoIncrement = true,
        primaryKey = true,
    },
    column_name = {
        type = DBManager.TEXT(),
        allowNull = false,
    }
})
```

### Example
```lua
-- create table
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
```

## Example (using SQLite)

```lua
-- connect to database (MySQL)
local conn = DBManager:new({
    dialect = 'sqlite',
    storage = 'database/db.sqlite'
})
```

## Model Querying

## Simple INSERT queries
First, a simple example.

```lua
service:create({1, "LODS", 20})
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

## License

[Click here to see the license.](https://github.com/lodsdev/database-management/blob/main/MIT-LICENSE.txt)

