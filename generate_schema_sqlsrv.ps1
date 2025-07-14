param (
    [string]$ConnectionString = "Server=(localdb)\MSSQLLocalDB;Database=Northwind;Integrated Security=True;"
)
$ErrorActionPreference = "Stop"
$dumpScript = @"
SELECT 
    t.name AS TableName,
    c.name AS ColumnName,
    ty.name AS DataType,
    c.max_length AS MaxLength,
    c.precision AS Precision,
    c.scale AS Scale,
    CASE 
        WHEN c.is_nullable = 1 THEN 'Y'
        ELSE 'N'
    END AS IsNullable,
    CASE 
        WHEN ic.column_id IS NOT NULL THEN 'PK'
        ELSE ''
    END AS IsPK
FROM 
    sys.tables t
    INNER JOIN sys.columns c ON t.object_id = c.object_id
    INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
    LEFT JOIN sys.key_constraints kc ON t.object_id = kc.parent_object_id 
        AND kc.type = 'PK'
    LEFT JOIN sys.index_columns ic ON kc.parent_object_id = ic.object_id 
        AND kc.unique_index_id = ic.index_id 
        AND c.column_id = ic.column_id
ORDER BY 
    t.name, c.column_id;
"@
# SQL 2017+ 支援 STRING_AGG，更早版本需改用 FOR XML PATH 產生 CSV
$indexScript = @"
SELECT 
    t.name AS TableName,
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns
FROM 
    sys.tables t
    INNER JOIN sys.indexes i ON t.object_id = i.object_id
    INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
    INNER JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE 
    i.type > 0  -- Exclude heaps
GROUP BY 
    t.name, i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY 
    t.name, i.name;
"@

$cn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
$cmd = New-Object System.Data.SqlClient.SqlCommand($dumpScript, $cn)
$cn.Open()
$reader = $cmd.ExecuteReader()
$schema = @()
while ($reader.Read()) {
    $row = [PSCustomObject]@{
        TableName   = $reader["TableName"]
        ColumnName  = $reader["ColumnName"]
        DataType    = $reader["DataType"]
        MaxLength   = $reader["MaxLength"]
        Precision   = $reader["Precision"]
        Scale       = $reader["Scale"]
        IsNullable  = $reader["IsNullable"]
        IsPK        = $reader["IsPK"]
    }
    if ($row.DataType.EndsWith("char") -or $row.DataType.EndsWith("text")) {
        $row.MaxLength = if ($row.MaxLength -eq -1) { "MAX" } else { $row.MaxLength }
        $row.DataType = "$($row.DataType)($($row.MaxLength))"
    } elseif ($row.Precision -ne 0 -and $row.Scale -ne 0) {
        $row.DataType = "$($row.DataType)($($row.Precision),$($row.Scale))"
    } elseif ($row.Precision -ne 0) {
        $row.DataType = "$($row.DataType)($($row.Precision))"
    }
    $row.DataType = $row.DataType.ToUpper()
    $schema += $row
}
$reader.Close()

# Get Index Information
$cmd = New-Object System.Data.SqlClient.SqlCommand($indexScript, $cn)
$reader = $cmd.ExecuteReader()
$indexes = @()
while ($reader.Read()) {
    $indexRow = [PSCustomObject]@{
        TableName     = $reader["TableName"]
        IndexName     = $reader["IndexName"]
        IndexType     = $reader["IndexType"]
        IsUnique      = $reader["IsUnique"]
        IsPrimaryKey  = $reader["IsPrimaryKey"]
        IndexColumns  = $reader["IndexColumns"]
    }
    $indexes += $indexRow
}
$reader.Close()
$cn.Close()
$markdown = @"
# 資料庫 Schema

"@
$widths = $(2, 24, 24, 16, 4, 32)
$ascEnc = [System.Text.Encoding]::GetEncoding("big5")
function FixWidth($idx, $text)
{
    $width = $widths[$idx]
    if ($text -eq '-') {
        return '-' * $width
    }
    $len = $ascEnc.GetByteCount($text)
    return $text + (' ' * ($width - $len))
}
foreach ($table in $schema | Group-Object TableName) {
    $markdown += "## 資料表 $($table.Name)nn"
    $markdown += "| PK | $(FixWidth 1 '欄位名稱') | $(FixWidth 2 '欄位說明') | $(FixWidth 3 '資料型別') | $(FixWidth 4 '空值') | $(FixWidth 5 '備註') |n"
    $markdown += "|-$(FixWidth 0 '-')-|-$(FixWidth 1 '-')-|-$(FixWidth 2 '-')-|-$(FixWidth 3 '-')-|:$(FixWidth 4 '-'):|-$(FixWidth 5 '-')-|n"
    foreach ($column in $table.Group) {
        $markdown += "| $(FixWidth 0 ($column.IsPK)) | $(FixWidth 1 $column.ColumnName) | $(FixWidth 2 ' ') | $(FixWidth 3 $column.DataType) | $(FixWidth 4 $column.IsNullable) | $(FixWidth 5 ' ') |n"
    }
    
    # Add index information for this table
    $tableIndexes = $indexes | Where-Object { $_.TableName -eq $table.Name }
    if ($tableIndexes) {
        $indexInfo = ($tableIndexes | ForEach-Object {
            $isUnique = if ($_.IsUnique) { "/UNIQUE" } else { '' }
            $isPrimary = if ($_.IsPrimaryKey) { "/PRIMARY_KEY" } else { '' }
            "- $($_.IndexType)$isUnique$isPrimary INDEX: $($_.IndexName)($($_.IndexColumns))"
        }) -join "n"
        $markdown += "n" + $indexInfo + "n"
    }
    $markdown += "n"
}

$markdown