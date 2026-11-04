# Dump a SQL Server schema to a flat text file for Claude to read.
# Stable across a session, so it lands in the cached prefix rather than
# being re-discovered every time.
#
#   .\db-schema.ps1 -Server myhost -Database mydb -Out schema.txt
param(
    [Parameter(Mandatory)][string]$Server,
    [Parameter(Mandatory)][string]$Database,
    [string]$Out = 'schema.txt'
)
$q = @"
SET NOCOUNT ON;
SELECT s.name + '.' + t.name + ' | ' + c.name + ' ' + ty.name +
       CASE WHEN ty.name IN ('varchar','nvarchar','char','nchar')
            THEN '(' + IIF(c.max_length = -1, 'max', CAST(c.max_length AS varchar(10))) + ')'
            ELSE '' END +
       CASE WHEN c.is_nullable = 0 THEN ' NOT NULL' ELSE '' END
FROM sys.columns c
JOIN sys.tables  t ON c.object_id   = t.object_id
JOIN sys.schemas s ON t.schema_id   = s.schema_id
JOIN sys.types  ty ON c.user_type_id = ty.user_type_id
ORDER BY s.name, t.name, c.column_id;
"@
sqlcmd -S $Server -d $Database -Q $q -h -1 -W | Out-File -Encoding utf8 $Out
Write-Host "wrote $Out"
