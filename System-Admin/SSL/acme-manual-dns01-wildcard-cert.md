# SSL - acme.sh 手動 DNS-01 申請萬用憑證（DNS 無 API 時）

DNS 由中華電信管理、無法用 API 改記錄時，用 [acme.sh](https://github.com/acmesh-official/acme.sh) 的**手動 DNS-01 模式**向 Let's Encrypt 申請萬用憑證（`*.tfc119.com.tw` + `tfc119.com.tw`）。

> ⚠️ **範圍說明：** 本篇是「手動、臨時」流程，**不會自動續約**。
> DNS 服務商有 API 時，請看 [acme.sh + Cloudflare 萬用憑證](./acme-cloudflare-wildcard-cert.md)。

**實測環境（2026-11-03）：** Proxmox LXC（Linux）、acme.sh、Let's Encrypt、中華電信 DNS 管理介面。

## 1. 前提

* 萬用憑證只能用 DNS-01 驗證。
* 一次簽 `*.tfc119.com.tw` 與 `tfc119.com.tw`，會產生**兩組 TXT 值**，名稱相同，必須並存。

## 2. 安裝 acme.sh 並設定 CA

```bash
curl https://get.acme.sh | sh -s email=<真實可收信的email>
source ~/.bashrc
acme.sh --set-default-ca --server letsencrypt
```

> `email=` 要用真實信箱，Let's Encrypt 會拒絕 `example.com` 這類保留網域。細節見[舊筆記第 1.1 節](./acme-cloudflare-wildcard-cert.md#11-修正帳號-email安裝時填錯或日後要改)。

## 3. 第一階段：取得 TXT 值

```bash
acme.sh --issue --dns -d 'tfc119.com.tw' -d '*.tfc119.com.tw' \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

輸出會有兩組：

```
Domain: '_acme-challenge.tfc119.com.tw'
TXT value: '<值 1>'
Domain: '_acme-challenge.tfc119.com.tw'
TXT value: '<值 2>'
```

## 4. 在中華電信 DNS 新增兩筆 TXT

| 類型 | 名稱 | 值 |
|---|---|---|
| TXT | `_acme-challenge.tfc119.com.tw` | `"<值 1>"` |
| TXT | `_acme-challenge.tfc119.com.tw` | `"<值 2>"` |

注意事項：

* 中華電信介面要求**自行在字串頭尾加上半形雙引號**（RFC 4408 多字串格式）。ACME 的值只有 43 字元，遠低於單一字串 255 字元的上限，不需拆段。
* **兩筆各自獨立新增**，不要寫在同一筆，也不要互相覆蓋。
* 引號必須是半形 `"`，全形 `「」` 或 `“”` 會變成值的一部分而驗證失敗。

## 5. 確認 TXT 已生效

```bash
dig +short TXT _acme-challenge.tfc119.com.tw @8.8.8.8
```

兩個值都出現（輸出帶引號是正常的）才進下一步。不確定時，也可以直接問中華電信的權威 NS：`dig +short NS tfc119.com.tw` 找出 NS，再用 `dig TXT ... @<該 NS>` 查詢。

## 6. 第二階段：驗證並簽發

```bash
acme.sh --renew -d 'tfc119.com.tw' --force \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

看到 `Your cert is in:` 且沒有 `Error` 即成功。

## 7. 匯出與驗證憑證

```bash
mkdir -p ~/cert-export
acme.sh --install-cert -d 'tfc119.com.tw' \
  --key-file       ~/cert-export/privkey.pem \
  --cert-file      ~/cert-export/cert.pem \
  --ca-file        ~/cert-export/chain.pem \
  --fullchain-file ~/cert-export/fullchain.pem
chmod 600 ~/cert-export/privkey.pem

openssl x509 -in ~/cert-export/cert.pem -noout -subject -issuer -dates -ext subjectAltName
```

預期結果：

```
subject=CN=tfc119.com.tw
issuer=C=US, O=Let's Encrypt, CN=YE2
notBefore=Nov  3 06:25:44 2026 GMT
notAfter=Feb  1 06:25:43 2027 GMT
X509v3 Subject Alternative Name:
    DNS:*.tfc119.com.tw, DNS:tfc119.com.tw
```

| 檔案 | 用途 |
|---|---|
| `fullchain.pem` | 伺服器憑證 + 中繼憑證，nginx 的 `ssl_certificate` 用這個 |
| `privkey.pem` | 私鑰，權限 600，不可外流 |
| `cert.pem` / `chain.pem` | 分開的伺服器憑證與中繼憑證，Apache 或需拆檔的設備使用 |

## 8. 續約與清理

* 效期 90 天，**手動模式不會自動續約**，acme.sh 的 cron 對此憑證會失敗。
* 建議在到期前約 30 天（本例 2027-01-01 前後）重做第 3 到 7 步，並在行事曆設提醒。
* 驗證完成後，兩筆 TXT 可以刪除，不影響已簽發的憑證。

### 常見問題

| 現象 | 原因與處理 |
|---|---|
| `incorrect TXT record` | 值抄錯、引號用成全形、只加了一筆，或舊值殘留。用第 5 節的 `dig` 核對 |
| `Invalid status` | 中華電信權威 DNS 尚未同步，等幾分鐘再 `--renew` |
| 每次 `--renew` 要的值都不同 | 第一階段與第二階段之間重跑了 `--issue`。以最新一次輸出的值為準 |
| Let's Encrypt 拒絕 email | 帳號 email 用了保留網域，見[舊筆記第 1.1 節](./acme-cloudflare-wildcard-cert.md#11-修正帳號-email安裝時填錯或日後要改) |

## 9. 部署到 nginx

```bash
# 在 LXC 上傳到目標主機暫存
scp ~/cert-export/fullchain.pem ~/cert-export/privkey.pem <user>@<host>:/tmp/

# 在目標主機備份、安裝、測試、reload
D=/etc/nginx/ssl; TS=$(date +%F-%H%M)
sudo mkdir -p $D/backup-$TS && sudo cp -a $D/*.pem $D/backup-$TS/
sudo install -m 644 /tmp/fullchain.pem $D/fullchain.pem
sudo install -m 600 /tmp/privkey.pem  $D/privkey.pem
sudo nginx -t && sudo systemctl reload nginx
shred -u /tmp/privkey.pem; rm -f /tmp/fullchain.pem
```

從外部驗證：

```bash
echo | openssl s_client -connect <FQDN>:443 -servername <FQDN> 2>/dev/null \
  | openssl x509 -noout -issuer -dates -subject
```

回復：把 `backup-<時間戳>/` 內的檔案複製回 `$D`，再 `nginx -t && systemctl reload nginx`。

## 10. 安全注意事項

* 私鑰權限 600，不放到雲端硬碟或版本控制。
* 不要把 `CF_Token` 等憑證寫進會被 commit 的腳本。
* TXT 值本身不是機密，但文件範例仍以佔位符表示。
