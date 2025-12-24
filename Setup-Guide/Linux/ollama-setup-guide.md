# DGX Spark: Ollama AI 服務部署 (含 Nginx 資安防護)

**環境說明**

* **硬體**：GIGABYTE AI TOP ATOM (NVIDIA DGX Spark)
* **OS**：Ubuntu 24.04 LTS
* **目標**：部署 Ollama (AI 後端) + Nginx (反向代理/IP 白名單/隱藏檔防護)
* **專案路徑**：`<your-dir>/ollama` (請自行替換為實際掛載點，如 `/mnt/data/project/ollama`)

---

## 🧐 1. 檢查與安裝 Docker (v2+)

DGX 通常預載了 Docker，但我們需要確認其版本是否支援 `docker compose` (V2)。

### 1.1 檢查版本

請先執行以下指令檢查版本：

```bash
docker compose version
```

*   **若顯示 `Docker Compose version v2.x.x`**：代表環境已就緒，請**直接跳至「2. 專案目錄與權限設定」**。
*   **若顯示 command not found 或版本過舊**：請依序執行以下步驟進行安裝。

### 1.2 安裝 Docker Engine (若環境未就緒)

#### 設定 Repository 與 GPG 金鑰

這步是為了讓 `apt` 信任 Docker 官方的軟體來源，避免安裝到被竄改的套件。

移除舊版 (確保環境乾淨)
```bash
sudo apt-get remove docker docker-engine docker.io containerd runc
```

安裝必要傳輸套件
```bash
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg
```

下載 Docker 官方 GPG 公鑰 (數位印鑑)
```bash
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
```

設定 Repo 來源
```bash
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

#### 安裝套件

更新套件清單
```bash
sudo apt-get update
```

安裝最新版 Docker Engine 與 Compose Plugin
```bash
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

#### 驗證安裝

確認 Compose 版本 (應顯示 v2.x.x，注意指令沒有連字符)
```bash
docker compose version
```

確認 NVIDIA Container Toolkit 是否存在 (DGX 必備)
```bash
nvidia-ctk --version
```

---

## 📂 2. 專案目錄與權限設定

依據資料碟掛載規範，建立專案目錄並設定權限。

1. 建立目錄結構 (將 `<your-dir>` 替換為實際路徑，例如 `/mnt/data/project/ollama/ollama_models`)
```bash
mkdir -p <your-dir>/ollama/ollama_models
```

2. 設定歸屬權 (將 `<username>` 替換為你的帳號)
```bash
sudo chown -R <username>:<username> <your-dir>/ollama
```

3. 設定目錄權限 (隱私保護：其他人禁止進入)
```bash
sudo chmod 700 <your-dir>/ollama
```

---

## ⚙️ 3. 設定檔部署

您可以直接從 [example-code/ollama/](../../example-code/ollama/) 目錄中取得以下檔案，或手動建立。

請在 `<your-dir>/ollama/` 目錄下建立以下兩個檔案。

### 3.1 `nginx.conf` (資安守門員)

* **功能**：IP 白名單過濾、隱藏檔封鎖、反向代理、串流優化。

```nginx
worker_processes 1;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;

    server {
        # Nginx 監聽容器內的 80 port (對應外部 11434)
        listen 80;
        server_name localhost;

        # --- 防火牆白名單 ACL ---
        
        # 允許 Docker 內部網段
        allow 10.168.89.0/24;

        # 允許信任 IP (請自行增減)
        allow 127.0.0.1;
        allow 172.16.2.73; 
        allow 192.168.2.198;

        # 拒絕其他所有連線 (Default Deny)
        deny all;

        # > ⚠️ **小撇步**：若後續有更改 `nginx.conf` 中的允許 IP，請執行以下指令重新載入設定：
        # `docker restart ollama-nginx`

        # 禁止存取隱藏檔 (以 . 開頭的檔案)
        location ~ /\. {
            deny all;
            access_log off;
            log_not_found off;
        }


        location / {
            # 反向代理到 Ollama 容器
            proxy_pass http://ollama:11434;

            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            
            # 支援 LLM Streaming (打字機效果)
            proxy_buffering off;
            
            # 延長超時時間
            proxy_read_timeout 600s;
        }
    }
}
```

### 3.2 `docker-compose.yml` (服務編排)

> ⚠️ **注意**：請將 volumes 路徑修改為你的 `<your-dir>`。

```yaml
version: '3.8'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    restart: always
    environment:
      - TZ=Asia/Taipei
      - OLLAMA_KEEP_ALIVE=5m
      - OLLAMA_MAX_LOADED_MODELS=3
      - OLLAMA_NUM_PARALLEL=2
      - OLLAMA_HOST=0.0.0.0
    networks:
      ollama-net:
        ipv4_address: 10.168.89.2
    volumes:
      # 資料落地 (請修改 <your-dir> 為實際路徑)
      - <your-dir>/ollama/ollama_models:/root/.ollama
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              device_ids: ['0']
              capabilities: [gpu]

  nginx-guard:
    image: nginx:alpine
    container_name: ollama-nginx
    restart: always
    environment:
      - TZ=Asia/Taipei
    networks:
      ollama-net:
        ipv4_address: 10.168.89.3
    ports:
      # 只有 Nginx 負責對外開放 Port
      - "11434:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/localtime:/etc/localtime:ro

networks:
  ollama-net:
    driver: bridge
    ipam:
      config:
        - subnet: 10.168.89.0/24
```

---

## 🚀 4. 啟動服務

在專案目錄下執行：

啟動服務
```bash
docker compose up -d
```

若修改過設定檔，強制重建
```bash
docker compose up -d --force-recreate
```

---

## ✅ 5. 驗收測試 (Verification)

### 5.1 Postman 測試 (連線與資安)

* **目的**：確認 Nginx 轉發正常，且防火牆規則生效。
* **Method**: `POST`
* **URL**: `http://<Server-IP>:11434/api/generate`
* **Body (JSON)**:
```json
{
  "model": "llama3",
  "prompt": "Test connection",
  "stream": false
}
```


* **判定標準**：
1. **正常連線**：Status Code 為 `200 OK`，並回傳 JSON 結果。
2. **IP 封鎖測試** (使用手機 4G 測試)：應回傳 `403 Forbidden`。
3. **隱藏檔測試** (GET `http://<Server-IP>:11434/.env`)：應回傳 `403 Forbidden`。



### 5.2 curl 測試 (Streaming 串流)

* **目的**：確認 Nginx 沒有卡住串流緩衝，能實現打字機效果。
* **指令** (請在終端機執行)：

`N` 參數是關鍵 (No buffer)
```bash
curl -N -X POST http://<Server-IP>:11434/api/generate \
  -d '{
    "model": "llama3",
    "prompt": "請自我介紹",
    "stream": true
  }'
```


* **判定標準**：
* 終端機畫面應**一行一行**即時跳出 JSON 資料。
* 若卡住許久才一次全部噴出，代表 `proxy_buffering off;` 設定未生效。

### 5.3 GPU 狀態檢查 (GPU Status)

* **目的**：確認 Ollama 容器是否正確抓取到 GPU 資源。

執行指令
```bash
docker exec -it ollama nvidia-smi
```

* **判定標準**：
* 應顯示 NVIDIA 顯示卡狀態表 (如 GPU 型號、記憶體使用量)。
* 若顯示 `command not found` 或錯誤訊息，請檢查 `docker-compose.yml` 中的 `deploy.resources` 設定。

---

## 🔧 6. 簡易故障排除 (Troubleshooting)

Log 檢查 (基本功) - 查 Nginx 設定錯誤
```bash
docker logs ollama-nginx
```

查 GPU/模型載入錯誤
```bash
docker logs ollama
```


* **Nginx 403 Forbidden**：檢查 Client IP 是否已加入 `nginx.conf` 的 `allow` 清單。
* **連線被拒 (Connection Refused)**：
1. 檢查 UFW 防火牆：`sudo ufw status` (需 allow 11434)。
2. 檢查容器狀態：`docker compose ps` (需為 Up)。


---

## ⚠️ 資安風險提示與未來補強建議

目前的部署架構（Nginx 反向代理 + IP 白名單 + 隱藏檔防護）已具備基礎防護能力，優於多數直接開放 `0.0.0.0` 的預設環境。然而在企業資安標準下，建議留意以下風險並視需求進行優化。

### 1. 現行架構風險揭露 (Risk Disclosure)

本方案目前僅建議運行於**「受信任的封閉內網環境」**：

*   **明文傳輸風險 (Cleartext Transmission)**：
    目前服務運行於 `HTTP` 協定，資料在內網傳輸過程中皆為明文。若內網中存在惡意嗅探工具（如 Wireshark），連線內容可能被截獲。**請勿輸入機敏個資或公司核心機密。**
*   **認機不認人 (Device-Based Trust)**：
    驗證機制僅基於來源 IP。若白名單內的設備安全性受損，攻擊者可能藉此存取 AI 服務。

### 2. 未來補強建議 (Roadmap)

若服務需擴大使用規模或符合資安稽核標準，建議實施以下防護：

*   **加密傳輸 (HTTPS)**：導入 SSL/TLS 憑證，防止中間人攻擊 (MITM) 與內容竊聽。
*   **身分驗證 (Authentication)**：
    *   **短期**：於 Nginx 啟用 `Basic Auth` 進行帳密驗證。
    *   **長期**：整合 OIDC 或 LDAP (SSO) 系統。
*   **API Key 管理**：為不同應用程式核發獨立 API Key，以便追蹤流量與控管權限。
*   **稽核紀錄 (Audit Logging)**：將 Log 拋送至集中式日誌伺服器 (如 ELK)，以符合稽核規範。