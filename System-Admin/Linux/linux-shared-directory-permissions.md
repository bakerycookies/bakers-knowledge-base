# Linux 共用目錄權限管理標準作業 (Group & SGID)

## 📝 應用場景

本指南適用於建立**多人協作**或**服務共用**（如 Docker 容器與開發者共用）的資料夾，確保符合以下資安與協作需求：

1.  **✅ 特定群組成員**（如開發者、專案成員）具備完全讀寫權限。
2.  **✅ 服務進程**（如 Docker/Web Server）具備存取權限。
3.  **⛔ 其他閒雜人等**（Others）完全禁止存取（防窺視、防誤刪）。
4.  **🔄 權限繼承一致性**：確保新增檔案自動繼承群組權限（避免 A 建立的檔案 B 無法修改）。

---

## 👥 1. 建立專案群組與人員配置
首先建立一個專用群組，並將相關協作人員加入。

**參數說明：**
*   `<group_name>`：專案群組名稱，例如 `ai-team`, `docker-users`。
*   `-a` (append)：追加模式，保留使用者原有的群組。
*   `-G` (group)：指定要加入的群組。

1. 建立群組
```bash
sudo groupadd <group_name>
```

2. 將使用者加入群組
```bash
sudo usermod -aG <group_name> <username>
```

範例：將當前使用者加入 ai-team
```bash
sudo usermod -aG ai-team $USER
```

> [!IMPORTANT]
> ℹ️ **注意**：修改群組後，使用者必須**登出並重新登入**（或重開機），新的群組身分才會生效。可使用 `groups` 指令驗證。

## 👑 2. 設定目錄擁有者 (Ownership)
將目錄的「擁有者」設為管理者或 root，並將「所屬群組」設為專案群組。

**參數說明：**
*   `-R`：遞迴處理，包含子目錄與所有檔案。
*   `<owner>`：擁有者，通常設為 `root`（若配合 Docker）或專案負責人。
*   `<group>`：設定為剛剛建立的專案群組。

語法：chown -R <owner>:<group> <directory_path>
```bash
sudo chown -R <owner>:<group> <directory_path>
```

範例：將 /mnt/data 設定為 root 擁有，群組為 ai-team
```bash
sudo chown -R root:ai-team /mnt/data
```

## 🔒 3. 設定目錄權限 (Permissions) - 770 原則
設定權限為 `770`，確保群組內暢行無阻，群組外完全隔離。

**權限解讀 (770)：**
*   **Owner (7 = rwx)**：讀/寫/執行 (Root 或 Docker Daemon 擁有完整權限)。
*   **Group (7 = rwx)**：讀/寫/執行 (群組成員可完全控制)。
*   **Others (0 = ---)**：無權限 (禁止讀取、寫入、進入目錄)。

設定權限
```bash
sudo chmod -R 770 <directory_path>
```

## 🧬 4. 設定 SGID (Set Group ID) - 關鍵步驟
這是協作環境最重要的設定。設定 SGID 後，在此目錄下**新增的檔案或資料夾**，會自動繼承父目錄的「群組」，而不是建立者的預設群組。

**操作說明：**
*   `g+s`：給 Group 加上 Set-GID 屬性。

對目錄本身設定 SGID
```bash
sudo chmod g+s <directory_path>
```

**若目錄內已有既有資料夾：**
建議使用 `find` 指令遞迴設定所有子目錄：
```bash
find <path> -type d -exec chmod g+s {} +
```

## ✅ 5. 驗證與測試

**步驟 1：檢查目錄權限**
預期輸出應包含 `drwxrws---`，其中 `s` 代表 SGID 已生效。
```bash
ls -ld <directory_path>
```

**步驟 2：測試寫入與權限繼承**
建議切換成群組內成員進行測試。
```bash
cd <directory_path>
```

建立測試檔案
```bash
touch test_file.txt
```

查看檔案權限（預期結果：群組應自動變為 `<group>`）
```bash
ls -l test_file.txt
```

## 🚫 6. 特殊場景：建立私有目錄 (斬斷共享繼承)
當需要在這個大共享目錄中，建立一個**僅限個人存取**（其他群組成員無法進入）的私人資料夾時，需手動切斷權限與群組繼承。

### 操作步驟

**1. 建立資料夾**
```bash
mkdir <private_folder>
```

**2. 修改歸屬權 (關鍵)**
將擁有者與群組都改回你自己，切斷與 `ai-team` 的關聯。`$USER` 是當前使用者變數。
```bash
sudo chown $USER:$USER <private_folder>
```

**3. 設定私有權限 (700)**
*   **Owner (7)**：只有你可以讀寫執行。
*   **Group (0)**：群組成員 (含協作人員) 禁止存取。
*   **Others (0)**：其他人禁止存取。

```bash
sudo chmod 700 <private_folder>
```

### 驗證結果
使用 `ls -ld <private_folder>` 檢查，應顯示：
`drwx------  <user> <user> ... <private_folder>`

*   **說明**：此設定下，即使父目錄有 SGID，因為群組擁有者已被改為你的個人群組，且權限排除了 Group，因此共享繼承被阻斷。
*   **備註**：Root (含 Docker Daemon) 仍可讀取此目錄，但一般使用者（包含原本在同群組的其他人員）將無法進入。
