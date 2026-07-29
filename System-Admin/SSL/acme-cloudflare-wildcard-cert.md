# SSL - acme.sh + Cloudflare DNS 申請萬用憑證 (Wildcard Certificate)

這篇筆記記錄如何使用 [acme.sh](https://github.com/acmesh-official/acme.sh) 搭配 Cloudflare DNS API，
透過 DNS-01 驗證方式申請子網域萬用憑證（例如 `*.example.com`）。

> ⚠️ **範圍說明：本篇僅涵蓋「單次手動申請」流程。**
> 不包含自動續約（renewal / cron job）設定，也不包含 Docker 容器化部署。
> 若未來要做自動續約，需另外設定 `acme.sh --cron` 排程或搭配 systemd timer，屆時再另立筆記記錄。

Let's Encrypt 的萬用字元憑證（Wildcard Certificate）**只支援 DNS-01 challenge**，不支援 HTTP-01，
所以不論用哪套工具，都必須透過 DNS 服務商的 API 自動建立 `_acme-challenge` TXT 記錄來完成驗證。

## 1. 安裝 acme.sh

```bash
curl https://get.acme.sh | sh -s email=你的email@example.com
source ~/.bashrc   # 或重開 terminal 讓 acme.sh 指令生效
```

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

> **關於 ARI 訊息：** `ARI suggestedWindow` 與 `Next renewal time` 只是 acme.sh 根據 Let's Encrypt 的 ARI（Renewal Info）機制計算出的建議續期時間窗，**只是記錄用途，不會自動幫你續期**。要讓它真正自動續約，必須另外設定 cron 或 systemd timer 定期執行 `acme.sh --cron`（本篇不涵蓋此設定）。

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
