# 🍞 Bakery's Knowledge Base

> **"Baking fresh code and serving hot solutions."**

歡迎來到 **Bakery 的技術烘焙坊**。
這裡是一個全端工程師 (Full Stack Developer) 兼 MIS 的技術筆記庫，存放著我在開發與維運過程中累積的知識碎屑 (Breadcrumbs)、SOP 手冊與踩坑紀錄。

## 🚀 技術領域 (Tech Stack)

這裡主要涵蓋以下領域的技術筆記：

* **Frontend**: React (TypeScript)
* **Backend**: Python, Django (REST API)
* **Database**: MariaDB, PostgreSQL, SQL Optimization
* **System Admin / DevOps**: macOS Config, Windows Config, Proxmox, Linux, Network

---

## 📂 筆記目錄 (Table of Contents)

為了方便檢索，所有筆記皆依照「功能領域」與「作業系統/語言」進行分類。

### 🛠️ 環境建置 (Setup Guide)
*重灌電腦、建置開發環境的標準作業程序 (SOP)*

* **Git / GitHub**
    * [Git 專案上傳流程：從本地初始化到 GitHub 遠端部署](./Setup-Guide/Git/git-local-to-github-setup.md) - *將本地專案上傳至 GitHub 的完整 SOP 與狀況排除*
* **Shell / CLI**
    * [CLI 效率優化：Alias 別名與自動化腳本](./Setup-Guide/Shell/cli-aliases-automation.md) - *自訂指令別名與跨平台環境部署腳本*
* **macOS**
    * [macOS Python 環境重建與接管 SOP](./Setup-Guide/macOS/mac-python-clean-install.md) - *移除官方安裝檔，改用 Homebrew 完美管理 Python 3.12+*
    * [macOS 終端機環境建置 (iTerm2 + Oh My Zsh)](./Setup-Guide/macOS/mac-terminal-setup.md) - *從 Homebrew 到 Zsh Plugins 的完整配置 SOP*
* **Linux**
    * [Ubuntu 24.04 (ARM64) 安裝 LM Studio 指南](./Setup-Guide/Linux/install-lm-studio-ubuntu-arm64.md) - *解決 ARM 架構相容性問題與 Sandbox 錯誤*
    * [DGX Spark: Ollama AI 服務部署 (含 Nginx 資安防護)](./Setup-Guide/Linux/ollama-setup-guide.md) - *從 Docker 安裝到 IP 白名單防護的完整 SOP*

### ⚙️ 系統維運 (System Admin)
*伺服器管理、網路設定、MIS 實務操作*

* **macOS**
    * [macOS Hosts 設定與 Proxmox 連線手冊](./System-Admin/macOS/mac-hosts-config.md) - *修改 /etc/hosts 指定內網解析 IP*
* **Linux**
    * [Linux 網路基礎：主機識別與名稱解析 (Hostname & DNS)](./System-Admin/Linux/linux-hostname-dns.md)
    * [Linux 系統管理：SSH 安全連線與金鑰管理](./System-Admin/Linux/linux-ssh-config.md)
    * [Linux 系統管理：檔案權限與 ACL (Permissions)](./System-Admin/Linux/linux-permissions.md)
    * [Linux 共用目錄權限管理標準作業 (Group & SGID)](./System-Admin/Linux/linux-shared-directory-permissions.md)
    * [Linux 磁碟擴充指南：建立新分割區與自動掛載 (fstab)](./System-Admin/Linux/linux-disk-expansion-mount.md)
* **SSL**
    * [acme.sh + Cloudflare DNS 申請萬用憑證 (Wildcard Certificate)](./System-Admin/SSL/acme-cloudflare-wildcard-cert.md) - *單次手動申請流程，不含自動續約與 Docker 容器化*

### 🧱 後端開發 (Backend Development)
*Django, Python, REST API 設計模式*

* *(施工中... 預計新增 Django REST Framework 權限控管筆記)*

### 🎨 前端開發 (Frontend Development)
*React, TypeScript, UI/UX*

* *(施工中...)*

### 🗄️ 資料庫 (Database)
*MariaDB, PostgreSQL, SQL Query Tuning*

* *(施工中...)*

---

## 📝 關於本專案

這是一個持續演進的知識庫。
如果您發現筆記內容有誤，或有更好的實作建議，歡迎提交 Issue 或 Pull Request。

### Author
**Bakery**
* Full Stack Engineer & MIS
* Focus on: React / Django / System Architecture