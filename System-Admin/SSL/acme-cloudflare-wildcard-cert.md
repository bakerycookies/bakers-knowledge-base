# SSL - acme.sh + Cloudflare DNS 申請萬用憑證 (Wildcard Certificate)

這篇筆記記錄如何使用 [acme.sh](https://github.com/acmesh-official/acme.sh) 搭配 Cloudflare DNS API，
透過 DNS-01 驗證方式申請子網域萬用憑證（例如 `*.example.com`）。

> ⚠️ **範圍說明：本篇涵蓋「手動申請 + 自動續約排程」流程。**
> 不包含 Docker 容器化部署。
> acme.sh 的 installer 在安裝時會自動建立每日 cron job（詳見 [第 8 節](#8-自動續約cron)），不需額外手動設定排程。

Let's Encrypt 的萬用字元憑證（Wildcard Certificate）**只支援 DNS-01 challenge**，不支援 HTTP-01，
所以不論用哪套工具，都必須透過 DNS 服務商的 API 自動建立 `_acme-challenge` TXT 記錄來完成驗證。

## 1. 安裝 acme.sh

```bash
curl https://get.acme.sh | sh -s email=你的真實email@example.com
source ~/.bashrc   # 或重開 terminal 讓 acme.sh 指令生效
```

> ⚠️ **`email=` 必須是「真實可收信」的信箱，不要用 `example.com` 這類保留網域。** 這個信箱會被寫入 `~/.acme.sh/account.conf` 作為 ACME 帳號的聯絡信箱。
> ZeroSSL 對信箱網域不嚴格，矇混得過去；但 **Let's Encrypt 會明確拒絕 `example.com`**，等到日後想用 `--server letsencrypt` 簽發時就會報 `contact email has forbidden domain "example.com"` 而失敗（見下方「修正帳號 email」）。
> email **不需要跟你的網域相同**，用 gmail 等第三方信箱完全沒問題。

### 1.1 修正帳號 email（安裝時填錯、或日後要改）

誤用了 `example.com` 佔位字，或想換聯絡信箱，可依下列步驟修正。`-m` 只改全域 `account.conf` 裡的 `ACCOUNT_EMAIL`；若該 CA 已用舊 email 建了半成的帳號，需一併清除重註冊：

```bash
# 1. 確認舊的 example.com 存在哪些設定檔
grep -rl "example.com" ~/.acme.sh/

# 2. 把全域設定裡的佔位 email 換成真實信箱
sed -i 's#你的email@example.com#你的真實email@gmail.com#g' ~/.acme.sh/account.conf

# 3. 移除用舊 email 建到一半的 Let's Encrypt 帳號（讓註冊重新開始）
rm -rf ~/.acme.sh/ca/acme-v02.api.letsencrypt.org

# 4. 用真實 email 重新註冊 Let's Encrypt 帳號
acme.sh --register-account -m 你的真實email@gmail.com --server letsencrypt
```

> 第 3 步只刪 Let's Encrypt 的帳號目錄，**不影響 ZeroSSL 帳號與已簽好的憑證**。要改 ZeroSSL 的 email，換成對應 server 與帳號目錄即可。

## 2. 建立 Cloudflare API Token

到 Cloudflare Dashboard → **My Profile → API Tokens → Create Token**，設定以下權限：

* **Zone : DNS : Edit**
* 限定在要簽憑證的那個 Zone（域名），不要給全部 Zone

> 目前 Cloudflare 已提供現成的 **「編輯區域 DNS」(Edit zone DNS) API 權杖範本**，直接在 Create Token 頁面選用該範本，再選擇要套用的網域（Zone）即可快速建立，不需要手動逐項設定權限。

**不要使用舊版的 Global API Key**（`CF_Key` + `CF_Email`），該金鑰權限範圍過大，一旦外洩影響是整個 Cloudflare 帳號，而非單一 Zone。

## 3. 設定環境變數

```bash
export CF_Token="你的API_Token"
```

只需要設定 `CF_Token` 即可，**不需要**額外設定 `CF_Account_ID`。

## 4. 簽發萬用憑證

```bash
acme.sh --issue --dns dns_cf -d '*.bakerybag.ggff.net'
```

acme.sh 會透過 Cloudflare API 自動建立 `_acme-challenge` TXT 記錄完成 DNS-01 驗證，驗證通過後會自動清除該筆 TXT 記錄，全程不需手動操作 DNS 後台。

> **預設 CA 為 ZeroSSL，可用 `--server letsencrypt` 切換：**
>
> ```bash
> acme.sh --issue --dns dns_cf -d '*.bakerybag.ggff.net' --server letsencrypt
> ```
>
> 兩者皆為公用信任 CA，差異在 rate limit 與政策立場（詳見 [第 7.1 節](#71-本機檢查憑證檔案不需部署)）。續約沿用簽發時的 CA，換 CA 需加 `--force` 重簽。

> **萬用憑證不含裸網域（apex）：** `*.bakerybag.ggff.net` 只涵蓋子網域，不含 `bakerybag.ggff.net` 本身。需要的話加第二個 `-d`：
>
> ```bash
> acme.sh --issue --dns dns_cf -d '*.bakerybag.ggff.net' -d 'bakerybag.ggff.net' --server letsencrypt
> ```

### 簽發成功的輸出範例

```
[Wed Jul 29 06:46:04 UTC 2026] Your cert is in: /root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.cer
[Wed Jul 29 06:46:04 UTC 2026] Your cert key is in: /root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.key
[Wed Jul 29 06:46:04 UTC 2026] The intermediate CA cert is in: /root/.acme.sh/*.bakerybag.ggff.net_ecc/ca.cer
[Wed Jul 29 06:46:04 UTC 2026] And the full-chain cert is in: /root/.acme.sh/*.bakerybag.ggff.net_ecc/fullchain.cer
[Wed Jul 29 06:46:06 UTC 2026] ARI suggestedWindow: 2026-10-12T23:59:59Z to 2026-10-14T23:59:59Z
[Wed Jul 29 06:46:06 UTC 2026] Next renewal time picked from ARI window: 2026-10-14T06:46:05Z
```

看到四個 `is in:` 訊息且沒有任何 `Error` 字樣，就代表憑證簽發成功。

> **關於 ARI 訊息：** `ARI suggestedWindow`／`Next renewal time` 是 Let's Encrypt ARI 機制（RFC 9773）建議的續期時間窗，本身不會主動續期。真正觸發續約的是 [第 8 節](#8-自動續約cron) 的每日 cron，它會依此視窗判斷是否該續約；ARI 的作用只是讓各用戶的續約時間錯開。

## 5. 簽發完成後的檔案結構

```
root@acme:~# ls -al /root/.acme.sh/*.bakerybag.ggff.net_ecc/
total 36
-rw-r--r-- 1 root root 1318 Jul 29 06:46 '*.bakerybag.ggff.net.cer'
-rw------- 1 root root  580 Jul 29 06:46 '*.bakerybag.ggff.net.conf'
-rw-r--r-- 1 root root  509 Jul 29 06:45 '*.bakerybag.ggff.net.csr'
-rw-r--r-- 1 root root  216 Jul 29 06:45 '*.bakerybag.ggff.net.csr.conf'
-rw------- 1 root root  227 Jul 29 06:45 '*.bakerybag.ggff.net.key'
drwxr-xr-x 2 root root 4096 Jul 29 06:46  .
drwx------ 7 root root 4096 Jul 29 06:44  ..
-rw-r--r-- 1 root root 2368 Jul 29 06:46  ca.cer
-rw-r--r-- 1 root root 3686 Jul 29 06:46  fullchain.cer
```

各檔案用途說明：

| 檔案 | 用途 |
|---|---|
| `*.bakerybag.ggff.net.cer` | 伺服器憑證本身（不含中繼 CA） |
| `*.bakerybag.ggff.net.conf` | acme.sh 內部設定檔，記錄簽發方式（DNS provider）、涵蓋網域、續期時間等資訊。**權限 600，內容敏感，不可外流** |
| `*.bakerybag.ggff.net.csr` / `.csr.conf` | 簽發時使用的憑證請求檔（Certificate Signing Request），簽發後留存但實務上不再需要使用 |
| `*.bakerybag.ggff.net.key` | **私鑰**，權限 600，只有 root 可讀寫。務必妥善保管，不可外洩或複製到權限寬鬆的位置 |
| `ca.cer` | Let's Encrypt 的中繼憑證（Intermediate CA） |
| `fullchain.cer` | 伺服器憑證 + 中繼憑證串接而成的憑證鏈 |

**實務部署時**，多數服務（如 nginx）需要的是 **`fullchain.cer`（當作 cert）+ `*.key`（私鑰）** 這兩個檔案，而不是單獨的 `.cer`。

## 6. 安全注意事項

* **私鑰 (`.key`) 與 `.conf` 檔案權限皆為 600**，僅 root 可讀寫，不要放寬權限、不要複製到其他機器或雲端硬碟。
* **Cloudflare API Token 只給 `Zone.DNS:Edit` 且限定單一 Zone**，不要使用 Global API Key，降低外洩後的影響範圍。
* `export CF_Token=...` 屬於當次 shell session 的暫存環境變數，若要長期使用建議寫入受保護的環境變數檔案（例如權限 600 的 `.env` 或 secret manager），不要直接寫死在會被版本控制追蹤的腳本中。

## 7. 驗證憑證

簽發完成後，務必確認憑證內容、效期與憑證鏈是否正確。分成兩種情境：**尚未部署到伺服器**（只驗檔案本身）與**已部署到伺服器**（從外部連線驗證）。

### 7.1 本機檢查憑證檔案（不需部署）

直接用 `openssl` 檢視 acme.sh 產出的憑證檔，確認網域、簽發者、效期、憑證鏈是否正確：

```bash
# 1. 檢視伺服器憑證完整內容（CN/SAN、簽發者、效期）
openssl x509 -in /root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.cer -noout -text

# 2. 只看有效期限
openssl x509 -in /root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.cer -noout -dates

# 3. 驗證憑證鏈是否完整（伺服器憑證能否對到中繼 CA）
openssl verify -CAfile /root/.acme.sh/*.bakerybag.ggff.net_ecc/ca.cer \
  /root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.cer
```

重點檢查項目：

| 項目 | 預期值 |
|---|---|
| Subject Alternative Name (SAN) | 包含 `*.bakerybag.ggff.net` |
| Issuer（簽發者） | 視簽發時使用的 CA 而定：acme.sh 預設為 **ZeroSSL**（如 `ZeroSSL ECC DV SSL CA 2`）；若簽發時加 `--server letsencrypt` 則為 **Let's Encrypt** 的中繼 CA（如 `R3` / `E5`）。兩者都是公用信任的 CA，對網站訪客沒有差別 |
| Not Before / Not After（效期） | 共 90 天 |
| `openssl verify` 結果 | 回傳 `OK` |

### 7.2 部署後從外部連線驗證

憑證裝上 nginx 或其他服務後，從外部對該網域發起 TLS 連線，確認實際上線的憑證鏈是否完整、是否受公用信任：

```bash
# 完整 TLS 交握資訊
openssl s_client -connect sub.bakerybag.ggff.net:443 -servername sub.bakerybag.ggff.net </dev/null

# 只看憑證關鍵欄位（較乾淨）
echo | openssl s_client -connect sub.bakerybag.ggff.net:443 \
  -servername sub.bakerybag.ggff.net 2>/dev/null \
  | openssl x509 -noout -dates -issuer -subject

# 用 curl 快速確認（需替換成「實際有服務在跑」的子網域）
curl -vI https://sub.bakerybag.ggff.net 2>&1 | grep -E 'subject|issuer|expire|SSL certificate'
```

> ⚠️ **curl 沒輸出通常是連線層失敗，不是 grep 沒抓到。** 常見原因：憑證未部署、該子網域 443 無服務。先拿掉 grep 看原始錯誤：
> ```bash
> curl -vI https://sub.bakerybag.ggff.net 2>&1 | head -40
> ```
> 訊息對照：`Connection refused`（443 無服務）、`Could not resolve host`（無 DNS 記錄）、`SSL connection timeout`（TLS 交握失敗）。只想確認簽發是否成功，用 7.1 驗檔案即可，不必先部署。

### 7.3 線上第三方檢測（推薦）

部署上線後，可用外部服務同時檢查憑證鏈、TLS 協定、cipher 強度等整體設定：

* **SSL Labs**：`https://www.ssllabs.com/ssltest/analyze.html?d=sub.bakerybag.ggff.net`

## 8. 自動續約（cron）

[第 1 節](#1-安裝-acmesh) 安裝時，acme.sh installer 已自動建立每日 cron job，**不需再手動設定排程**。

installer 預設會做三件事：複製 `acme.sh` 到 `~/.acme.sh/`、建立 shell alias、安裝每日執行的 cron，內容大致如下：

```bash
51 4,10,16,22 * * * "/root/.acme.sh"/acme.sh --cron --home "/root/.acme.sh" > /dev/null
```

> **時段是隨機產生的**（例如 `51 4,10,16,22` = 每天 04:51/10:51/16:51/22:51 各跑一次），目的是分散所有用戶的檢查時間、避免集中打 Let's Encrypt API。實際時段以自己 `crontab -l` 為準。

`acme.sh --cron` 每次執行會逐筆檢查已簽發的憑證，**是否續約、何時續約由各憑證的 ARI 視窗決定**（見 [第 4 節](#4-簽發萬用憑證)）；cron 只負責「到時間就檢查」，未到期不會重複簽發。

### 8.1 確認 cron 是否存在

```bash
crontab -l | grep acme.sh
```

有看到 `acme.sh --cron` 那行就代表自動續約已在運作。若安裝時跳過了 cron（例如用了 `--nocron` 參數），可用以下指令補裝：

```bash
acme.sh --install-cronjob
```

移除則用 `acme.sh --uninstall-cronjob`。

### 8.2 手動測試續約流程

想確認 cron 真的能跑通，可手動觸發一次 `--cron` 看輸出（未到期時不會真的續簽，只會顯示 skip）：

```bash
acme.sh --cron --home "/root/.acme.sh"
```

強制立即續約某張憑證（忽略 30 天門檻，測試或排查用）：

```bash
acme.sh --renew -d '*.bakerybag.ggff.net' --force
```

### 8.3 續約後部署憑證（`--install-cert`）

cron 只負責續約並更新 `~/.acme.sh/` 底下的檔案，**不會搬到 nginx 等服務路徑、也不會 reload**。要自動部署，需設定 `--install-cert`，讓憑證複製到服務路徑並於更新後執行 reload：

```bash
acme.sh --install-cert -d '*.bakerybag.ggff.net' \
  --key-file       /etc/nginx/ssl/bakerybag.key \
  --fullchain-file /etc/nginx/ssl/bakerybag.fullchain.cer \
  --reloadcmd      "nginx -t && systemctl reload nginx"
```

設定過一次後，`--reloadcmd` 會被寫入該憑證的 `.conf`，之後每次 cron 自動續約成功都會自動執行這條部署指令，不需再手動介入。

> ⚠️ `--reloadcmd` 以 root 權限執行，指令內容務必確認安全。先 `nginx -t` 測試語法再 reload，避免設定錯誤時憑證已更新但服務未套用。

### 8.4 本機模擬續約後部署（進階／選讀）

若手邊沒有對外服務的 nginx，想在不影響正式環境的情況下驗證「續約 → 自動部署 → reload」整條流程，可參考獨立筆記：[acme.sh 本機模擬 nginx 自動部署測試](./acme-local-nginx-deploy-test.md)。
