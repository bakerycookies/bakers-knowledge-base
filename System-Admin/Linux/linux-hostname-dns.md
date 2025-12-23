# Linux 網路基礎：主機識別與名稱解析 (Hostname & DNS)

- **適用**：全端工程師、MIS
- **目標**：理解 Linux 如何識別自己 (Hostname) 以及如何透過名字找到其他電腦 (DNS/Hosts)。

## 1. Hostname (主機名稱)
- **定義**：電腦給自己取的「綽號」。
- **用途**：
  - 本機識別 (Shell 提示字元會顯示 `user@hostname`)。
  - 方便管理員區分不同用途的伺服器 (如 `prod-db-01`, `test-web-02`)。
- **誤區**：單純修改 Hostname 只有電腦自己知道。若沒有設定 DNS 或 Hosts，外部電腦無法透過這個名字連線。

## 2. 解析機制 (Resolution)
當輸入 `ssh prod-db-1` 時，系統尋找 IP 的優先順序：

### A. 本機 Hosts 檔 (優先權高)
- **概念**：電腦私人的手寫通訊錄。
- **路徑**：
  - Linux/macOS: `/etc/hosts`
  - Windows: `C:\Windows\System32\drivers\etc\hosts`
- **優點**：立即生效，不需依賴外部伺服器。
- **缺點**：無法集中管理，IP 變更時需逐台修改。

### B. DNS 伺服器 (正規作法)
- **概念**：公司的總機查號台。
- **常見紀錄類型**：
  - **A Record (Address)**：將名字對應到 IPv4 (例如 `db.local` -> `192.168.1.100`)。**這是最基礎且必要的設定。**
  - **CNAME (Alias)**：將別名對應到另一個 Hostname (例如 `db` -> `prod-db-1.local`)。

## 💡 MIS 實戰筆記
- **修改 Hostname 後**：通常建議重開機或重啟服務，確保所有程式都抓到新名字。
- **Ping 不到名字？**：先檢查 `/etc/hosts` 有沒有寫錯，或用 `nslookup <hostname>` 檢查 DNS 是否有回應。