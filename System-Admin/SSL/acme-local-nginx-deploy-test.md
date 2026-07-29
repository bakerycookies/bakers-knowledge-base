# SSL - acme.sh 本機模擬 nginx 自動部署測試

> 本篇是 [acme.sh + Cloudflare 萬用憑證申請筆記](./acme-cloudflare-wildcard-cert.md) 第 8.4 節的延伸筆記，用來驗證「續約 → 自動部署 → reload」整條流程是否正確運作。

沒有對外服務的 nginx 時，可裝一個只綁 `127.0.0.1` 的 nginx 純跑流程，不開放對外、不需要 DNS。目的是確認 `--install-cert` 的 `--reloadcmd` 在續約時真的會被執行，不是驗證 TLS 是否受公用信任（本機用 `localhost` 與憑證的 `*.bakerybag.ggff.net` 不匹配，瀏覽器會報錯，但不影響流程驗證）。

> 以下以 Debian/Ubuntu（apt）為例；RHEL/Rocky/Alma 系列改用 `dnf install nginx`，設定檔目錄可能在 `/etc/nginx/conf.d/` 或需改 `/etc/nginx/nginx.conf` 的 include，依發行版調整。

## 1. 安裝 nginx 並建立憑證部署目錄

```bash
apt update && apt install -y nginx
mkdir -p /etc/nginx/ssl
```

## 2. 先以預設設定啟動 nginx（在建立測試 conf 之前）

```bash
systemctl enable --now nginx
```

> ⚠️ **順序很重要：務必在建立 `acme-test.conf` 之前先啟動 nginx。** nginx 的 systemd unit 有 `ExecStartPre=/usr/sbin/nginx -t`，啟動前會先測試設定語法；若 `acme-test.conf` 已存在但憑證還沒搬進 `/etc/nginx/ssl/`，`nginx -t` 會因 `cannot load certificate` 失敗，導致啟動也跟著失敗，陷入「啟動失敗 → reload 失敗」的循環。先以預設設定啟動、running 中的 nginx 不受新 conf 影響（要 reload 才會套用），可避開這個問題。

## 3. 寫一個只綁 127.0.0.1:443 的最小 server block

```bash
cat > /etc/nginx/conf.d/acme-test.conf <<'EOF'
server {
    listen 127.0.0.1:443 ssl;
    server_name localhost;

    ssl_certificate     /etc/nginx/ssl/bakerybag.fullchain.cer;
    ssl_certificate_key  /etc/nginx/ssl/bakerybag.key;

    location / { return 200 "acme deploy test ok\n"; }
}
EOF
```

## 4. 測試語法（預期失敗）

```bash
nginx -t
```

此時 `/etc/nginx/ssl/` 底下還沒有憑證，`nginx -t` 會報 `cannot load certificate ... No such file or directory`，**這是預期的**，不是設定寫錯。下一步 `--install-cert` 把憑證搬過去後就會通過。nginx 仍維持 running（用啟動時的舊設定，未 reload 不受影響）。

## 5. 設定 `--install-cert`（首次會複製憑證並執行一次 reload）

```bash
acme.sh --install-cert -d '*.bakerybag.ggff.net' \
  --key-file       /etc/nginx/ssl/bakerybag.key \
  --fullchain-file /etc/nginx/ssl/bakerybag.fullchain.cer \
  --reloadcmd      "nginx -t && systemctl reload nginx"
```

`--install-cert` 會先把憑證複製到 `/etc/nginx/ssl/`，**檔案就位後**才執行 `--reloadcmd`，此時 `nginx -t` 已能通過、`systemctl reload nginx` 也因 nginx 已在運行而成功。看到 `Reload successful` 即代表首次部署完成。

設定完成後，`--key-file`、`--fullchain-file`、`--reloadcmd` 會被寫入 `/root/.acme.sh/*.bakerybag.ggff.net_ecc/*.bakerybag.ggff.net.conf`，日後 cron 續約成功就會自動複製並 reload。

## 6. 模擬續約，觀察 reloadcmd 是否被執行

```bash
acme.sh --renew -d '*.bakerybag.ggff.net' --force
```

觀察重點：acme.sh 輸出應依序出現 `Cert success`（續約成功）→ `Installing key to` / `Installing full chain to`（搬憑證到部署路徑）→ `Running reload cmd: nginx -t && systemctl reload nginx` → `Reload successful`，代表續約後確實自動跑了部署指令。接著確認憑證檔案已更新：

```bash
# 確認部署路徑的憑證檔案 mtime 是剛剛續約的時間（與上面 Installing 訊息的時間一致）
ls -l /etc/nginx/ssl/

# 確認 nginx 仍正常運行（reload 沒把服務搞掛）
systemctl status nginx --no-pager

# 本機連線確認 nginx 有吃到憑證（會回 200，TLS 錯誤可忽略）
curl -k https://127.0.0.1/
```

> `-k` 讓 curl 忽略憑證與網域不匹配的錯誤，這裡只驗證「nginx 能讀到憑證、443 有服務」，不驗證 TLS 信任鏈。

## 7. 驗證完成後清理（視需求）

```bash
# 移除 acme.sh 的自動部署設定（只解除 install-cert，不影響憑證本身）
acme.sh --install-cert -d '*.bakerybag.ggff.net' --key-file /etc/nginx/ssl/bakerybag.key --fullchain-file /etc/nginx/ssl/bakerybag.fullchain.cer --reloadcmd ""

# 移除測試用的 nginx 設定與憑證複本
rm /etc/nginx/conf.d/acme-test.conf
rm -f /etc/nginx/ssl/bakerybag.key /etc/nginx/ssl/bakerybag.fullchain.cer
nginx -t && systemctl reload nginx

# 若不再需要 nginx，可整個移除
apt remove --purge -y nginx && apt autoremove -y
```
