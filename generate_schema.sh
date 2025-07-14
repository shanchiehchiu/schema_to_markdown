#!/bin/bash

# 設定資料庫連線資訊
DB_USER="root"
DB_PASSWORD="yourpassword"
DB_NAME="yourdatabase"

# 查詢資料表結構
dumpScript="SELECT 
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
    TABLE_SCHEMA = '$DB_NAME'
ORDER BY 
    TABLE_NAME, ORDINAL_POSITION;"

# 查詢索引資訊
indexScript="SELECT 
    TABLE_NAME AS TableName,
    INDEX_NAME AS IndexName,
    NON_UNIQUE AS IsUnique,
    GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX) AS IndexColumns
FROM 
    INFORMATION_SCHEMA.STATISTICS
WHERE 
    TABLE_SCHEMA = '$DB_NAME'
GROUP BY 
    TABLE_NAME, INDEX_NAME
ORDER BY 
    TABLE_NAME, INDEX_NAME;"

# 執行查詢並處理結果
schema=$(mysql -u$DB_USER -p$DB_PASSWORD -e "$dumpScript" -B)
indexes=$(mysql -u$DB_USER -p$DB_PASSWORD -e "$indexScript" -B)

# 生成 Markdown 文件
markdown="# 資料庫 Schema\n\n"

# 處理資料表結構
while IFS=$'\t' read -r table column dataType maxLength precision scale isNullable keyType; do
    markdown+="## 資料表 $table\n\n"
    markdown+="| 主鍵 | 欄位名稱 | 資料型別 | 最大長度 | 精度 | 比例 | 是否允許空值 |\n"
    markdown+="|------|----------|----------|----------|------|------|--------------|\n"
    markdown+="| $( [[ "$keyType" == "PRI" ]] && echo "是" || echo "否" ) | $column | $dataType | $maxLength | $precision | $scale | $isNullable |\n\n"
done <<< "$schema"

# 處理索引資訊
while IFS=$'\t' read -r table index isUnique indexColumns; do
    markdown+="### 索引 $index\n"
    markdown+="- 索引名稱：$index\n"
    markdown+="- 是否唯一：$( [[ "$isUnique" == "0" ]] && echo "否" || echo "是" )\n"
    markdown+="- 包含欄位：$indexColumns\n\n"
done <<< "$indexes"

# 輸出 Markdown 文件
echo "$markdown"
