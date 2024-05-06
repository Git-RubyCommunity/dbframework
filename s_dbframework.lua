local ipairs            = ipairs;
local print             = print;

local string_format     = string.format;
local string_match      = string.match
local string_gsub       = string.gsub
local tostring          = tostring;

local os_clock          = os.clock;
local setTimer          = setTimer;

local table_concat      = table.concat;
local table_sort        = table.sort;
local table_insert      = table.insert;
local table_remove      = table.remove;

local dbConnect         = dbConnect;
local dbExec            = dbExec;
local dbQuery           = dbQuery;
local dbPoll            = dbPoll;
local dbFree            = dbFree;
local fetchRemote       = fetchRemote;

local fromJSON          = fromJSON;
local toJSON            = toJSON;
local destroyElement    = destroyElement;


local function handleDBError(dbConnection)

    if dbConnection then    
        dbExec(dbConnection, "ROLLBACK;")
    end

    print(strings[language][1])
end

local function connectToDatabase(dbId)

    for _, db in ipairs(databases) do
        if db.id == dbId then
            local connection, err = dbConnect("mysql", "dbname=" .. db.database .. ";host=" .. db.host, db.username,db.password, "share=1");

            if not connection then
                print(string_format(strings[language][2], err ));
                cancelEvent(true,string_format(strings[language][2], err ));
                return nil,string_format(strings[language][2], err );
            end
            
            return connection;
        end
    end
       print(string_format(strings[language][3]),dbId);
    return nil, string_format(strings[language][3], dbId);
end


local function executeQuery(dbId, callback, queryType, tableName, ...)

    local args = {...}
    local connection = connectToDatabase(dbId)

    if not connection then

        if callback and type(callback) == "function" then
             callback(false,strings[language][4]);
        end

        return false,strings[language][4];
    end

    local success = dbExec(connection, "START TRANSACTION;");

    if not success then
        handleDBError(connection);
        
        if isElement(connection) then
            destroyElement(connection);
        end

        if callback and type(callback) == "function" then
            callback(false, strings[language][5]);
        end

        return false, strings[language][5];
    end

    local queryString = "";

    if queryType == "free" then
    
        queryString = table_concat(args, " ");

    elseif queryType == "select" then

        queryString = string_format("SELECT * FROM %s WHERE %s", tableName, table_concat(args, " AND "));

    elseif queryType == "update" then

        queryString = string_format("UPDATE %s SET %s WHERE %s", tableName, args[1], args[2]);

    elseif queryType == "delete" then

        queryString = string_format("DELETE FROM %s WHERE %s", tableName, table_concat(args, " AND "));

    elseif queryType == "insert" then

        queryString = string_format("INSERT INTO %s (%s) VALUES (%s)", tableName, args[1], args[2]);

    elseif queryType == "create" then

        local columns = {};

        for i, column in ipairs(args) do

            if not string_match(column, "^.+%s.+$") then
                column = column .. " VARCHAR(255)";
            end

            table_insert(columns, column);
        end

        queryString = string_format("CREATE TABLE IF NOT EXISTS %s (id INT AUTO_INCREMENT PRIMARY KEY, %s)", tableName, table_concat(columns, ", "));

    elseif queryType == "drop" then

        queryString = string_format("DROP TABLE IF EXISTS %s", tableName);

    elseif queryType == "alter" then

        local action = args[1];

        if action == "modify" then

            queryString = string_format("ALTER TABLE %s MODIFY COLUMN IF EXISTS %s", tableName, args[2]);
            
        elseif action == "drop" then

            queryString = string_format("ALTER TABLE %s DROP COLUMN IF EXISTS %s", tableName, args[2]);

        elseif action == "add" then

            local columnDefinition = args[2];

            if not string_match(columnDefinition, "^.+%s.+$") then

                columnDefinition = columnDefinition .. " VARCHAR(255)";

            end

            queryString = string_format("ALTER TABLE %s ADD COLUMN IF NOT EXISTS %s", tableName, columnDefinition);

        else
            print(strings[language][6]);
            handleDBError(connection);
            
            if isElement(connection) then
                destroyElement(connection);
            end

            return false;
        end

    elseif queryType == "create_index" then

        local indexName = args[1];
        local columnName = args[2];

        queryString = string_format("CREATE INDEX IF NOT EXISTS %s ON %s (%s)", indexName, tableName, columnName);

    elseif queryType == "drop_index" then

        local indexName = args[1];

        queryString = string_format("DROP INDEX IF EXISTS %s ON %s", indexName, tableName);

    else

        if callback and type(callback) == "function" then
            callback(false, strings[language][7]);
            handleDBError(connection);
            if isElement(connection) then
                destroyElement(connection);
            end
        end

        handleDBError(connection);

        if isElement(connection) then
            destroyElement(connection);
        end

        return false;
    end

    local queryHandle, err = dbQuery(connection, queryString);

    if not queryHandle then

        print(string_format(strings[language][8], err));
        handleDBError(connection);

        if isElement(connection) then
            destroyElement(connection);
        end
        
        if callback and type(callback) == "function" then
            callback(false, string_format(strings[language][8], err));
        end

        return false;
    end

    local result, num_affected_rows, last_insert_id = dbPoll(queryHandle, -1);

    if not result then

        handleDBError(connection);
        
        if isElement(connection) then
            destroyElement(connection);
        end

        if callback and type(callback) == "function" then

            callback(false, strings[language][9]);

        end

        return false
    end

    dbFree(queryHandle);

    success = dbExec(connection, "COMMIT;");

    if not success then

        handleDBError(connection);
        
        if isElement(connection) then
            destroyElement(connection);
        end

        if callback and type(callback) == "function" then

             callback(false, strings[language][10]) ;

        end
        
        return false
    end

    if callback and type(callback) == "function" then 
        
        callback(true, strings[language][11], result, num_affected_rows, last_insert_id);
    else

        return result, num_affected_rows, last_insert_id;

    end

    if isElement(connection) then
        destroyElement(connection);
    end

    return true
    
end

local backupDirectory = "backups/";
local backupTrackingFile = backupDirectory .. "backup_files.json";

local function readBackupTrackingFile()
    local file = fileExists(backupTrackingFile) and fileOpen(backupTrackingFile);
    if not file then
        return {};
    end
    local size = fileGetSize(file);
    local content = size > 0 and fileRead(file, size) or "[]";
    fileClose(file);
    return fromJSON(content) or {};
end

local function writeBackupTrackingFile(backupFiles)

    local file = fileCreate(backupTrackingFile);

    fileWrite(file, toJSON(backupFiles));
    fileClose(file);
end

local function deleteOldestBackup(backupFiles)
    table_sort(backupFiles);
    while #backupFiles > maxBackupFiles do
        local oldestFile = table_remove(backupFiles, 1);

        if fileDelete(backupDirectory .. oldestFile) then
            return true
        else
            return false
        end
    end
end

local function backupDatabase(dbId)
    local dbConnection = connectToDatabase(dbId);
    if not dbConnection then
        print(strings[language][12]);
        return false;
    end

    local tablesResult = dbQuery(dbConnection, "SHOW TABLES;");
    local tables, numTables = dbPoll(tablesResult, -1);
    local timestamp = os.date("%Y_%m_%d_%H_%M_%S");

    local backupFileName = string_format("backup_%s_%s_id%s.sql",servername,timestamp,dbId)
    local backupFilePath = backupDirectory .. backupFileName;
    local backupFile = fileCreate(backupFilePath);
    fileWrite(backupFile, 
    [[
    /*
    ===================================
    ==  RubyCommunity Backup Script  ==
    ==    discord:@rubycommunity     ==
    ===================================
    */
    ]])
    for i=1, numTables do

        local tableName = tables[i]["Tables_in_" .. databases[dbId].database];
        
        local createTableResult = dbQuery(dbConnection, "SHOW CREATE TABLE " .. tableName .. ";");
        local createTable, numCreateTable = dbPoll(createTableResult, -1);
        local createTableStatement = createTable[1]["Create Table"] .. ";\n\n";

        fileWrite(backupFile, createTableStatement);

        local columnsResult = dbQuery(dbConnection, "SHOW COLUMNS FROM " .. tableName .. ";");
        local columns, numColumns = dbPoll(columnsResult, -1);
        local columnNames = {};

        for j=1, numColumns do
            table_insert(columnNames, columns[j].Field);
        end

        local dataResult = dbQuery(dbConnection, "SELECT * FROM " .. tableName .. ";");
        local data, numRows = dbPoll(dataResult, -1);

        for k=1, numRows do
            local values = {};
            for _, columnName in ipairs(columnNames) do
                local value = data[k][columnName];

                if value == nil then
                    table_insert(values, "NULL");
                else
                    table_insert(values, "'" .. tostring(value):gsub("'", "\\'") .. "'");
                end
            end
            local insertQuery = ("INSERT INTO " .. tableName .. " (" .. table_concat(columnNames, ", ") .. ") VALUES (" .. table_concat(values, ", ") .. ");\n");
            
            fileWrite(backupFile, insertQuery);
        end

        fileWrite(backupFile, "\n")
 
    end

    fileClose(backupFile);

    local backupFiles = readBackupTrackingFile();

    table_insert(backupFiles, backupFileName);

    if cloudBackup and diskBackup or cloudBackup and not diskBackup then 
        print(backupFileName)
        createPaste(key, description, tostring(backupFileName), "sql", backupFilePath)
    end

    deleteOldestBackup(backupFiles);
    writeBackupTrackingFile(backupFiles);

    if isElement(dbConnection) then
        destroyElement(dbConnection);
    end

    return true;
end

function createPaste(key, description, name, syntax, contents)
    if cloudBackup == true then 
        local function escapeNewlines()
            if fileExists(contents) then
                local file = fileOpen(contents, true)
                local content = fileRead(file, fileGetSize(file))
                fileClose(file)
                content = string_gsub(content, "\n", [[\n]])
                return content
            else
                return string_gsub(contents, "\n", [[\n]])
            end
        end

        local thefile = escapeNewlines()
        local postData = string_format('{"key":"%s","description":"%s","sections":[{"name":"%s","syntax":"%s","contents": "%s"}]}', key, description, name, syntax, thefile)

        fetchRemote(
            "https://api.paste.ee/v1/pastes",
            {
                method = 'POST',
                headers = {
                    ["Content-Type"] = "application/json"
                },
                postData = postData
            }, 
            function(responseData, errno)
                local response = fromJSON(responseData)
                if response and response.success then
                    print("Backup created: " .. response.link)
                else
                    for _, error in ipairs(response.errors) do
                        print(string_format("|error code:%s| |error message:%s| |status:%s|", error.code, error.message, tostring(response.success)))
                    end
                end
            end
        )
    end
end

if cloudBackup or diskBackup then
    setTimer(function()
        backupDatabase(1);
    end, backuptime, 0)
end