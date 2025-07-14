param (
    [string]$ConnectionString = "server=localhost;uid=root;pwd=yourpassword;database=yourdatabase;"
)
$ErrorActionPreference = "Stop"

# 查詢資料表結構
$dumpScript = @"
SELECT 
    TABLE_NAME AS TableName,
    COLUMN_NAME AS ColumnName,
    COLUMN_TYPE AS DataType,
    CHARACTER_MAXIMUM_LENGTH AS MaxLength,
    NUMERIC_PRECISION AS Precision,
    NUMERIC_SCALE AS Scale,
    IS_NULLABLE AS IsNullable,
    COLUMN_KEY AS KeyType
FROM 
    INFORMATION_SCHEMA.COLUMNS
WHERE 
    TABLE_SCHEMA = 'yourdatabase'
ORDER BY 
    TABLE_NAME, ORDINAL_POSITION;
"@

# 查詢索引資訊
$indexScript = @"
SELECT 
    TABLE_NAME AS TableName,
    INDEX_NAME AS IndexName,
    NON_UNIQUE AS IsUnique,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS IndexColumns
FROM 
    INFORMATION_SCHEMA.STATISTICS
WHERE 
    TABLE_SCHEMA = 'yourdatabase'
GROUP BY 
    TABLE_NAME, INDEX_NAME
ORDER BY 
    TABLE_NAME, INDEX_NAME;
"@

# 建立 MySQL 連線
Add-Type -Path "C:\path\to\MySql.Data.dll"  # 請根據實際路徑調整
$cn = New-Object MySql.Data.MySqlClient.MySqlConnection($ConnectionString)
$cn.Open()

# 執行資料表結構查詢
$cmd = $cn.CreateCommand()
$cmd.CommandText = $dumpScript
$reader = $cmd.ExecuteReader()
$schema = @()
while ($reader.Read()) {
    $row = [PSCustomObject]@{
        TableName  = $reader["TableName"]
        ColumnName = $reader["ColumnName"]
        DataType   = $reader["DataType"]
        MaxLength  = $reader["MaxLength"]
        Precision  = $reader["Precision"]
        Scale      = $reader["Scale"]
        IsNullable = $reader["IsNullable"]
        KeyType    = $reader["KeyType"]
    }
    $schema += $row
}
$reader.Close()

# 執行索引資訊查詢
$cmd.CommandText = $indexScript
$reader = $cmd.ExecuteReader()
$indexes = @()
while ($reader.Read()) {
    $indexRow = [PSCustomObject]@{
        TableName    = $reader["TableName"]
        IndexName    = $reader["IndexName"]
        IsUnique     = $reader["IsUnique"]
        IndexColumns = $reader["IndexColumns"]
    }
    $indexes += $indexRow
}
$reader.Close()

$cn.Close()

# 生成 Markdown 文件
$markdown = @"
# 資料庫 Schema

"@
foreach ($table in $schema | Group-Object TableName) {
    $markdown += "## 資料表 $($table.Name)`n`n"
    $markdown += "| 主鍵 | 欄位名稱 | 資料型別 | 最大長度 | 精度 | 比例 | 是否允許空值 | 索引類型 |`n"
    $markdown += "|------|----------|----------|----------|------|------|--------------|----------|`n"
    foreach ($column in $table.Group) {
        $keyType = if ($column.KeyType -eq 'PRI') { '是' } else { '否' }
        $markdown += "| $keyType | $($column.ColumnName) | $($column.DataType) | $($column.MaxLength) | $($column.Precision) | $($column.Scale) | $($column.IsNullable) | $keyType |`n"
    }

    # 加入索引資訊
    $tableIndexes = $indexes | Where-Object { $_.TableName -eq $table.Name }
    if ($tableIndexes) {
        $indexInfo = ($tableIndexes | ForEach-Object {
            $isUnique = if ($_.IsUnique -eq 0) { '否' } else { '是' }
            "- $($_.IndexName) 索引：$($_.IndexColumns) (唯一: $isUnique)"
        }) -join "`n"
        $markdown += "`n" + $indexInfo + "`n"
    }
    $markdown += "`n"
}

$markdown
