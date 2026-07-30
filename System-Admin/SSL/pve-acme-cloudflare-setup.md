# SSL - Proxmox VE 內建 ACME + Cloudflare DNS-01 憑證設定

這篇筆記記錄如何使用 **Proxmox VE 內建的 ACME 功能**，搭配 Cloudflare DNS API，
以 DNS-01 驗證方式，讓 PVE 管理介面（`https://<node>:8006`）換上 Let's Encrypt 簽發的正式憑證，
取代預設的自簽憑證。

> ⚠️ **範圍說明：本篇涵蓋 PVE 內建 ACME 的帳號設定、DNS-01 Challenge Plugin 設定、節點憑證申請與自動續約流程。**
> 不包含 acme.sh 手動部署（見 [acme.sh + Cloudflare 萬用憑證申請筆記](./acme-cloudflare-wildcard-cert.md)）。
> PVE 的 ACME 功能是內建整合，續約由 `pve-daily-update.service` 自動處理，不需要另外設定 cron。

PVE 的 DNS-01 Challenge 底層沿用 acme.sh 專案的 `dnsapi` 腳本（約 100+ 種 DNS 供應商），
所以 Cloudflare 這端需要的憑證（`CF_Token`）跟手動用 acme.sh 是同一套。
DNS-01 的好處是**不需要對外開放 80 port**，很適合像這台 PVE 主機一樣走 Cloudflare Tunnel、
沒有公網 IP 直接對外的環境；也是**唯一能簽萬用字元憑證**的驗證方式。

---

## 1. 建立 Cloudflare API Token

到 Cloudflare Dashboard → **My Profile → API Tokens → Create Token**，設定以下權限：

* **Zone : DNS : Edit**
* 限定在要簽憑證的那個 Zone（域名），不要給全部 Zone

> 可直接用 Cloudflare 現成的**「編輯區域 DNS」(Edit zone DNS)** 範本，選好 Zone 即可快速建立。
> **不要使用舊版的 Global API Key**（`CF_Key` + `CF_Email`），權限範圍過大，外洩影響是整個帳號而非單一 Zone。

詳細畫面步驟與注意事項同 [acme.sh 筆記第 2 節](./acme-cloudflare-wildcard-cert.md#2-建立-cloudflare-api-token)，這裡不重複贅述。

---

## 2. 註冊 ACME 帳號（Datacenter → ACME → Accounts）

**GUI 操作：**

1. 左側樹狀圖點選 **Datacenter**，進入 **ACME** 分頁。
2. 切到 **Accounts** 子分頁，點擊 **Add**。
3. 填入：
   - **ACME Directory**：選 `Let's Encrypt V2`（正式環境）或 `Let's Encrypt V2 Staging`（測試用，不受 rate limit 限制，但簽出的憑證不受信任，僅供流程測試）
   - **E-Mail**：真實可收信的信箱（用來接收憑證到期/撤銷等通知，不需跟網域相同）
4. 勾選同意 ToS 後送出。

**對應 CLI 指令：**

```bash
pvenode acme account register default mail@example.com
```

> `default` 是帳號設定檔名稱，可自訂；不指定 `--directory` 時預設走 Let's Encrypt V2 正式環境。
> 要用測試環境（staging）驗證流程，加上：
> ```bash
> pvenode acme account register staging mail@example.com \
>   --directory https://acme-staging-v02.api.letsencrypt.org/directory
> ```

確認帳號是否註冊成功：

```bash
pvenode acme account list
pvenode acme account info default
```

---

## 3. 設定 DNS-01 Challenge Plugin（Datacenter → ACME → Challenges）

**GUI 操作：**

1. 同樣在 Datacenter → **ACME**，切到 **Challenges** 子分頁，點擊 **Add**。
2. **DNS API**：選擇 `Cloudflare Managed DNS`（下拉選單顯示名稱如此，對應的內部 API 代號仍是 `cf`，所以下方 CLI 指令的 `--api cf` 不受影響）。
3. **Plugin ID**：自訂一個名稱，例如 `cf-bakerybag`。
4. **API Token**：填入第 1 節建立的 Cloudflare API Token（對應欄位是 `CF_Token`）。
5. 確認送出。

**對應 CLI 指令：**

CLI 版本的 `--data` 參數吃的是「**一個檔案**，裡面每行一組 `KEY=VALUE`」，PVE 會把內容 base64 編碼後存進
`/etc/pve/priv/acme/plugins.cfg`。實際操作：

```bash
# 1. 建立暫存的憑證檔（權限收緊，避免外洩）
cat > /root/cf-token.env <<'EOF'
CF_Token=你的Cloudflare_API_Token
EOF
chmod 600 /root/cf-token.env

# 2. 新增 DNS-01 plugin
pvenode acme plugin add dns cf-bakerybag --api cf --data /root/cf-token.env

# 3. 內容已寫入 plugins.cfg，暫存檔可以刪除
rm -f /root/cf-token.env
```

確認 plugin 設定：

```bash
pvenode acme plugin list
pvenode acme plugin config cf-bakerybag
```

> ⚠️ 如果日後 Token 需要更換，用 `pvenode acme plugin set cf-bakerybag --data /root/new-cf-token.env` 覆蓋，同樣記得事後刪除暫存檔。

---

## 4. 套用網域並簽發憑證（Node → Certificates）

**GUI 操作：**

1. 左側樹狀圖點選該 **節點（Node）**，進入 **Certificates** 分頁。
2. 在 **ACME** 區塊點擊 **Add**，選擇網域類型：
   - `DNS` — 走剛設定的 DNS-01 Challenge Plugin
3. **Domain**：填入要簽的網域，例如 `pve.bakerybag.ggff.net`（PVE 目前一次只能對單一 domain 簽發，萬用字元憑證 `*.bakerybag.ggff.net` 也是同樣填法）。
4. **Plugin**：選第 3 節建立的 `cf-bakerybag`。
5. 送出後，點擊 **Order Certificates Now** 觸發簽發。

**對應 CLI 指令：**

```bash
# 設定節點要簽發的網域與對應 plugin
pvenode config set -acmedomain0 domain=pve.bakerybag.ggff.net,plugin=cf-bakerybag

# 觸發簽發
pvenode acme cert order

# 套用新憑證，重啟管理介面服務
systemctl restart pveproxy
```

> `-acmedomain0` 到 `-acmedomain5` 最多可設定 6 組網域（例如同時申請多個 SAN）。萬用字元憑證要連裸網域一起簽時，PVE 目前的 ACME 整合**不支援單一憑證多網域合併簽發**（不像 acme.sh 可以 `-d` 疊加），需要涵蓋多個網域時建議另外用 acme.sh 手動簽發再透過 **Upload Custom Certificate** 上傳（見 [acme.sh 筆記](./acme-cloudflare-wildcard-cert.md)）。

---

## 5. 驗證憑證

簽發完成後，從外部確認 PVE 管理介面已換上正式憑證：

```bash
echo | openssl s_client -connect pve.bakerybag.ggff.net:8006 \
  -servername pve.bakerybag.ggff.net 2>/dev/null \
  | openssl x509 -noout -dates -issuer -subject
```

重點檢查項目同 [acme.sh 筆記第 7 節](./acme-cloudflare-wildcard-cert.md#7-驗證憑證)：Issuer 是否為 Let's Encrypt 中繼 CA、效期是否為 90 天、瀏覽器連入是否不再顯示憑證警告。

---

## 6. 自動續約機制

PVE 的 ACME 憑證由 **`pve-daily-update.service`**（每日執行的 systemd service）自動檢查：
若憑證**已過期或將在 30 天內到期**，就會自動觸發續約，等同背景執行：

```bash
pvenode acme cert renew
```

不需要像 acme.sh 那樣另外設定 cron。手動確認/強制續約：

```bash
# 手動觸發檢查（未到 30 天門檻不會真的續簽）
pvenode acme cert renew

# 強制立即續約，忽略 30 天門檻（測試或排查用）
pvenode acme cert renew --force
```

續約成功後 PVE 會自動重載 `pveproxy`，不需要手動 `systemctl restart pveproxy`。

---

## 7. 安全注意事項

* **Cloudflare API Token 只給 `Zone.DNS:Edit` 且限定單一 Zone**，不要用 Global API Key。
* CLI 建立 plugin 時用的暫存憑證檔（如 `/root/cf-token.env`）**簽完就刪除**，內容已 base64 存進 `/etc/pve/priv/acme/plugins.cfg`（該檔案僅 root 可讀）。
* `/etc/pve/priv/` 底下的內容會透過 pmxcfs 同步到整個 cluster 所有節點，等同於叢集內所有 root 都能讀到 plugin 設定，**不要把跟 PVE 無關的高權限 Token 也塞進同一個 Cloudflare Zone**。

---

## 8. 疑難排解

* **簽發失敗時看任務記錄**：GUI 右下角任務清單，或 CLI 查看：
  ```bash
  journalctl -u pvedaemon --since "10 min ago" | grep -i acme
  ```
* **確認 DNS TXT 記錄有沒有正確建立/清除**：簽發過程中可用 `dig txt _acme-challenge.pve.bakerybag.ggff.net` 觀察（正常情況下驗證完成後 TXT 記錄會被自動清掉，如果卡住通常代表 Token 權限不夠或 Zone 選錯）。
* **plugin 設定內容打錯**：`pvenode acme plugin config cf-bakerybag` 確認 `--data` 是否正確寫入，寫錯就用 `pvenode acme plugin set` 覆蓋重新設定。
