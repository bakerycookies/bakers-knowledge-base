# macOS Hosts 設定 Proxmox 網址操作手冊

- **目標**：編輯 `/etc/hosts` 讓域名指向指定 IP，並確認解析與連線成功。
- **適用對象**：MIS、開發人員
- **前提**：需具備管理員權限 (sudo)；建議先備份原始 `/etc/hosts`。
- **情境**：當內部 DNS Server 尚未建立 A 紀錄，或需要測試新舊伺服器遷移（Migration）時，透過本機 Hosts 檔案可強制指定解析 IP。
- **注意**：請將範例中的 `your-domain.com.tw` 替換為實際使用的內部或外部網域。

  ## 步驟 1：取得 root 權限編輯 /etc/hosts
  1) 開啟 Terminal。
  2) 以 `sudo` 使用 nano 編輯：
  ```bash
  sudo nano /etc/hosts
  ```

  > 💡 提示：輸入密碼時不會顯示字元，直接輸入後按 Enter。

  ## 步驟 2：寫入 Hosts 設定

  1. 在 nano 中將游標移到檔案底部。
  2. 貼上/輸入以下內容（IP 與域名建議用 Tab 對齊）：

  ```bash
  # Proxmox Servers
  192.168.2.56    proxmox.your-domain.com.tw
  192.168.2.55   proxmoxbs.your-domain.com.tw
  ```

  3. 存檔與離開：
  - 按 Ctrl + Ｏ 然後按 Enter (寫入檔案)。
  - 按 Ctrl + X (離開編輯器)。

  ## 步驟 3：清除 DNS 快取

  macOS 會快取 DNS 紀錄，修改 Hosts 後需強制清除才能立即生效：
  ```bash
  sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
  ```

  > 執行後若無錯誤訊息輸出，即代表執行成功。

  ## 步驟 4：驗證解析結果

  以 ping 確認域名已解析到目標 IP：
  ```bash
  ping -c 2 proxmox.your-domain.com.tw
  ```
  - 檢查點：回應的 IP 必須是 192.168.2.56。
    - ✅ 正確：64 bytes from 192.168.2.56: ...
    - ❌ 錯誤：Unknown host 或 IP 仍是舊的外部 IP。

  ## 步驟 5：瀏覽器連線

  使用完整 URL（Proxmox 埠為 8006）：

  - Proxmox 主機：https://proxmox.your-domain:8006
  - Proxmox BS：https://proxmoxbs.your-domain:8006

  ## ✅ Check Point
  - 能夠成功看到 Proxmox 登入畫面。
  - 若伺服器已正確安裝 SSL 憑證（.crt/.key），瀏覽器應顯示鎖頭且連線為「安全」。