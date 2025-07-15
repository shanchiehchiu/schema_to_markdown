# schema_to_markdown

## 專案簡介

本專案提供自動化工具，協助你將 MySQL 或 SQL Server 資料庫的 Schema（資料表結構與索引）一鍵轉換為 Markdown 文件，方便文件化與團隊溝通。

支援 MySQL（Windows PowerShell、Linux/macOS Bash）與 SQL Server（Windows PowerShell）。

---

## 環境需求

### PowerShell 版本（Windows, MySQL）
- 需安裝 PowerShell
- 需安裝 MySql.Data.dll（.NET MySQL Connector）

### Bash 版本（Linux/macOS, MySQL）
- 需安裝 bash
- 需安裝 MySQL CLI 工具（mysql）

### PowerShell 版本（Windows, SQL Server）
- 需安裝 PowerShell
- 需安裝 .NET Framework（內建於大多數 Windows）
- 需有 SQL Server 權限（可查詢資料表結構）


---

## 安裝與設定

1. 複製本專案所有檔案至本地資料夾。
2. 根據你的作業系統與目標資料庫，編輯對應腳本中的資料庫連線資訊：
   - `generate_schema.ps1`（PowerShell, MySQL）：
     - 修改 `$ConnectionString`，填入正確的 server、uid、pwd、database。
     - 設定 `MySql.Data.dll` 的路徑。
   - `generate_schema.sh`（Bash, MySQL）：
     - 修改 `DB_USER`、`DB_PASSWORD`、`DB_NAME` 變數。
   - `generate_schema_sqlsrv.ps1`（PowerShell, SQL Server）：
     - 修改 `$ConnectionString`，填入正確的 SQL Server 連線資訊（如 Server、Database、帳號密碼等）。


---

## 使用方式

### PowerShell 版本（MySQL）
```powershell
# 在 Windows PowerShell 執行
powershell -ExecutionPolicy Bypass -File generate_schema.ps1
```

### Bash 版本（MySQL）
```bash
# 在 Linux/macOS 終端機執行
bash generate_schema.sh
```

### PowerShell 版本（SQL Server）
```powershell
# 在 Windows PowerShell 執行
powershell -ExecutionPolicy Bypass -File generate_schema_sqlsrv.ps1
```


---

## 輸出範例

產生的 Markdown 範例如下：

#### MySQL 輸出範例
```
# 資料庫 Schema

## 資料表 users

| 主鍵 | 欄位名稱 | 資料型別 | 最大長度 | 精度 | 比例 | 是否允許空值 | 索引類型 |
|------|----------|----------|----------|------|------|--------------|----------|
| 是   | id       | int      | 11       |      |      | 否           | 是       |
| 否   | name     | varchar  | 255      |      |      | 是           | 否       |

- idx_name 索引：name (唯一: 否)
```

#### SQL Server 輸出範例
```
# 資料庫 Schema

## 資料表 Products

| PK | 欄位名稱               | 欄位說明               | 資料型別           | 空值 | 備註                           |
|----|------------------------|------------------------|--------------------|:----:|--------------------------------|
| PK | ProductID              |                        | int                | N    |                                |
|    | ProductName            |                        | nvarchar           | N    |                                |
|    | SupplierID             |                        | int                | Y    |                                |

- CLUSTERED/PRIMARY_KEY INDEX: PK_Products(ProductID)
- NONCLUSTERED INDEX: IX_Products_SupplierID(SupplierID)
```


---

## 注意事項

- 請確認資料庫帳號有足夠權限查詢 `INFORMATION_SCHEMA`（MySQL）或系統 catalog（SQL Server）。
- 若遇連線問題，請檢查連線參數與網路設定。
- PowerShell 版本（MySQL）需安裝 MySql.Data.dll，並調整路徑。
- Bash 版本需安裝 mysql CLI 工具。
- PowerShell 版本（SQL Server）請確認 SQL Server 連線資訊正確且有查詢權限。


---

## 參考來源

本專案部分設計參考自 [SQL Schema 轉 Markdown Table](https://blog.darkthread.net/blog/sql-schema-to-markdown-table/)。

---

## 授權

本專案採用 MIT License。
