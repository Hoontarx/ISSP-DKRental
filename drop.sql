DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql = @sql + N'DROP TABLE IF EXISTS ' 
       + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';' + CHAR(13)
FROM sys.tables AS t
JOIN sys.schemas AS s ON t.schema_id = s.schema_id
WHERE s.name = 'pm';

PRINT @sql;  -- Review before executing
EXEC sp_executesql @sql;
