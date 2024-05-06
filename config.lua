
backuptime        = 0.5;    -- hours | ساعات

--- Clear the Backup Folder Before Make any Change | قبل از اعمال تغییرات محتوایات داخل پوشه بکاپ را حذف کنید ---
maxBackupFiles    = 5;   -- maximam files on disk +1 per/backuptime |  حداکثر تعداد فایل های بکاپ روی دیسک +1 فایل به ازای ساعت های مشخص شده
cloudBackup       = false; -- true | false       
diskBackup        = true; -- true | false      

language          = 'english'

key               = ''  -- api key from https://paste.ee/ for cloud backup
description       = 'https://www.youtube.com/watch?v=an702mzj9g8' -- description for backup file
databases = {{
    id = 1,
    host = "localhost",
    username = "root",
    password = "",
    database = "test"
}, {
    id = 2,
    host = "127.0.0.1",
    username = "root",
    password = "",
    database = "test2"
}};

strings = {
    ["english"] =  {
                     "Database operation failed.",
                     "Database connection error: %s",
                     "Database with ID %s not found.",
                     "Connection failed.",
                     "Transaction start failed",
                     "Invalid alter action.",
                     "Invalid query type",
                     "Query execution error: %s",
                     "Query poll failed",
                     "Transaction commit failed.",
                     "Query executed successfully.",
                     "[backup]: Failed to connect to database."
                    },
    ["persian"] =  {
                        "Amaliyat Database Movafaghiyat Amiz nabood.",
                        "Khata Dar Ertebat Ba Database : %s",
                        "Database Ba ID %s Peyda Nashod.",
                        "Ertebat Bargharar Nashod.",
                        "Amaliyat Shoroo Nashod ",
                        "Amalkard alter Na'Motabar Ast.",
                        "Noe query Na'Motabar Ast",
                        "Khataye Ejraye Query: %s",
                        "Khata Dar Query poll",
                        "Amaliyat commit Anjam Nashod.",
                        "Query Ba Movafaghiyat Ejra Shod.",
                        "[backup]: Ertebat Bargharar Nashod."
                    }

    -- feel free to add your language here ;D
};

--print(strings[language][1])

-- do not change this part --
servername = string.gsub (getServerName()," ","")
if cloudBackup and not diskBackup then
    if fileExists( "backups/backup_files.json" ) then
        fileDelete("backups/backup_files.json")
    end
    maxBackupFiles = 1
end
if backuptime < 0.5 then  
    backuptime = 0.5    -- min backuptime = 30 min
end
backuptime = backuptime * 3600000
-----------------end------------------
--[[
    
░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░
░░░░░░░░░░████████████████████░░░░░░░░░░
░░░░░░░░▒███████████████████████░░░░░░░░
░░░░░░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓███████████▓▒░░░░░░
░░░░░░░░░░░░░░░░░░░░░░░▒▓██████████░░░░░
░░░░░░░░░░░░░░░░░░░░░░░░░▒▓█████████▒░░░
░░▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░▒██████████░░░
▒█████████████████████░░░░░███████████░▒
░▒▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▒░░░░░██████████▓▒░
░░░░░░░░░░░░░░░░░░░░░░░░░░▓█████████▓░░░
░░░░░░░░░░░░░░░░░░░░░░░░▒▓████████▓▒░░░░
░░░░░░░▒▒▒▒▒▒▒░░░░░░▒▓▓█████████▓▒░░░░░░
░░░░░░░░▓█████▓░░░░░░▒▓████████▓░░░░░░░░
░░░░░░░░░▒▓█████▓░░░░░░▓█████▓▒░░░░░░░░░
░░░░░░░░░░░▒▓████▓▒░░░░░░▓█▓▒░░░░░░░░░░░
░░░░░░░░░░░░░▓█████▓░░░░░░▒░░░░░░░░░░░░░
░░░░░░░░░░░░░░▒▓█████▓░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░▒▓████▓░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░▓██▓░░░░░░░░░░░░░░░░░░
░░░░░░░░░░░░░░░░░░░▒▒░░░░░░░░░░░░░░░░░░░
]]