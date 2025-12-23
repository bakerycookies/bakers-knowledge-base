# Linux 系統管理：SSH 安全連線與金鑰管理

- **適用**：全端工程師、MIS
- **目標**：掌握 SSH 免密碼登入原理、金鑰部署流程及 Client 端快速連線設定。

## 1. 關鍵檔案與目錄結構

| 檔案/目錄 | 位置 (預設) | 權限要求 (嚴格) | 說明 |
| :--- | :--- | :--- | :--- |
| **.ssh 資料夾** | `~/.ssh/` | **700 (`drwx------`)** | 存放所有 SSH 設定，權限過寬會導致連線失敗。 |
| **Private Key** | `~/.ssh/id_rsa` | **600 (`-rw-------`)** | **私鑰 (鑰匙)**。存在 Client 端，絕對不可外流。 |
| **Public Key** | `~/.ssh/id_rsa.pub` | 644 (`-rw-r--r--`) | **公鑰 (鎖頭)**。可以公開給 Server。 |
| **Authorized Keys**| `~/.ssh/authorized_keys`| **600 (`-rw-------`)** | **Server 端**的授權清單。持有對應私鑰者可免密碼登入。 |
| **Known Hosts** | `~/.ssh/known_hosts` | 644 | **Client 端**紀錄的主機指紋，防止中間人攻擊 (Man-in-the-Middle)。 |
| **Config** | `~/.ssh/config` | 644 | **Client 端**的快速撥號設定 (Alias)。 |

## 2. 免密碼登入實作 SOP (Passwordless Login)

### Step 1: 在 Client 端 (如 Mac) 產生金鑰對
```bash
ssh-keygen -t ed25519 -C "bakery@macbook"
```

- 按 Enter 使用預設路徑，可選擇是否設定 Passphrase (密碼保護私鑰)。

### Step 2: 將公鑰部署到 Server
#### 方法 A：自動化指令 (推薦)

```bash
ssh-copy-id user@hostname
```

#### 方法 B：手動部署

1. 複製 Client 端 `id_ed25519.pub` 的內容。
2. 貼上至 Server 端 `~/.ssh/authorized_keys` 檔案中。
3. 務必檢查 Server 端檔案權限 (參考上方表格)。

## 3. SSH Config (快速連線技巧)
在 Client 端編輯 `~/.ssh/config`，可建立短別名：

```plaintext
Host db
    HostName 192.168.1.100
    User root
    Port 22
```

設定後，只需輸入 `ssh db` 即可連線。