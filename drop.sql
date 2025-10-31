-- ===============================================
-- Drop all user tables in the current database
-- (works in Azure SQL - ignores foreign key order)
-- ===============================================

DECLARE @sql NVARCHAR(MAX) = N'';

-- 1️⃣ Disable all constraints
SELECT @sql += 'ALTER TABLE [' + s.name + '].[' + t.name + '] NOCHECK CONSTRAINT ALL;'
FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id;

-- 2️⃣ Drop all tables
SELECT @sql += 'DROP TABLE [' + s.name + '].[' + t.name + '];'
FROM sys.tables AS t
    INNER JOIN sys.schemas AS s ON t.schema_id = s.schema_id;

-- 3️⃣ Execute it all at once
EXEC sp_executesql @sql;

PRINT '✅ All user tables dropped successfully.';