local dbGenerals = {}

function DBManager(dbName, directory)
    if (not directory) then
        directory = 'database'
    end
    
    local dbConnection = dbConnect('sqlite', ''..directory..'/'..dbName..'.db')

    if (not dbConnection) then
        return error(''..getResourceName(getThisResource())..': Failed to connect to database '..dbName..'!')
    end

    local db = {
        dbName = dbName,
        directory = directory,
        dbConnection = dbConnection
    }
    setmetatable(db, {__index = dbGenerals})
    
    return db
end

function dbGenerals:getDB()
    return self.dbConnection
end

function dbGenerals:CreateTable(tblName, tableDefinition)
    local query = dbExec(self.dbConnection, 'CREATE TABLE IF NOT EXISTS '..tblName..' ('..tableDefinition..')')
    if (not query) then
        return error(''..getResourceName(getThisResource())..': Failed to create table '..tblName..'!')
    end
    
    local function delete()
        dbExec(self.dbConnection, 'DROP TABLE '..tblName)
    end

    local function getTblName()
        return tblName
    end

    return {delete = delete, getTblName = getTblName}
end