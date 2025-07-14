# 指定資料庫連線字串，預設連線到本地的 Northwind 資料庫
param (
    [string]$ConnectionString = "Server=(localdb)\MSSQLLocalDB;Database=Northwind;Integrated Security=True;"
)
# 發生錯誤時立即中止腳本執行
$ErrorActionPreference = "Stop"
# 查詢所有資料表、欄位及主鍵等資訊的 SQL 語法
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
# 查詢各資料表索引資訊的 SQL 語法
# 注意：SQL 2017+ 支援 STRING_AGG，更早版本需改用 FOR XML PATH 產生 CSV
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

# 建立 SQL Server 連線物件
$cn = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
# 建立查詢 schema 的 SQL 命令物件
$cmd = New-Object System.Data.SqlClient.SqlCommand($dumpScript, $cn)
# 開啟資料庫連線
$cn.Open()
$reader = $cmd.ExecuteReader()
# 用來儲存所有欄位資訊的陣列
$schema = @()
while ($reader.Read()) {
        # 將每一欄位資訊封裝成物件
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
        $schema += $row  # 加入到 schema 陣列
}
$reader.Close()

# Get Index Information
# 建立查詢索引的 SQL 命令物件
$cmd = New-Object System.Data.SqlClient.SqlCommand($indexScript, $cn)
$reader = $cmd.ExecuteReader()
# 用來儲存所有索引資訊的陣列
$indexes = @()
while ($reader.Read()) {
        # 將每一筆索引資訊封裝成物件
    $indexRow = [PSCustomObject]@{
        TableName     = $reader["TableName"]
        IndexName     = $reader["IndexName"]
        IndexType     = $reader["IndexType"]
        IsUnique      = $reader["IsUnique"]
        IsPrimaryKey  = $reader["IsPrimaryKey"]
        IndexColumns  = $reader["IndexColumns"]
    }
        $indexes += $indexRow  # 加入到 indexes 陣列
}
$reader.Close()
# 關閉資料庫連線
$cn.Close()
# 初始化 Markdown 內容，準備寫入 schema 結果
$markdown = @"
# 資料庫 Schema

"@
# 設定各欄位在 Markdown 表格中的寬度（為了對齊美觀）
$widths = $(2, 24, 24, 16, 4, 32)
# 取得 Big5 編碼物件，用於計算中文字寬度
$ascEnc = [System.Text.Encoding]::GetEncoding("big5")
# 依照指定寬度補空白，確保表格對齊
function FixWidth($idx, $text)
{
    $width = $widths[$idx]
    if ($text -eq '-') {
        return '-' * $width
    }
    $len = $ascEnc.GetByteCount($text)
    return $text + (' ' * ($width - $len))
}
# 依照資料表分組，逐一產生 Markdown 表格內容
foreach ($table in $schema | Group-Object TableName) {
    # 新增資料表標題
    $markdown += "## 資料表 $($table.Name)nn"
    # 新增表格標題列
    $markdown += "| PK | $(FixWidth 1 '欄位名稱') | $(FixWidth 2 '欄位說明') | $(FixWidth 3 '資料型別') | $(FixWidth 4 '空值') | $(FixWidth 5 '備註') |n"
    # 新增表格分隔線
    $markdown += "|-$(FixWidth 0 '-')-|-$(FixWidth 1 '-')-|-$(FixWidth 2 '-')-|-$(FixWidth 3 '-')-|:$(FixWidth 4 '-'):|-$(FixWidth 5 '-')-|n"
    # 逐一將欄位資訊加入表格
    foreach ($column in $table.Group) {
        $markdown += "| $(FixWidth 0 ($column.IsPK)) | $(FixWidth 1 $column.ColumnName) | $(FixWidth 2 ' ') | $(FixWidth 3 $column.DataType) | $(FixWidth 4 $column.IsNullable) | $(FixWidth 5 ' ') |n"  # 欄位說明與備註可後續補充
    }
    
    # 將該資料表的索引資訊加入 Markdown
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