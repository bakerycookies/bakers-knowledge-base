# Ubuntu 24.04 (ARM64/NVIDIA DGX) 安裝 LM Studio 指南

## 📝 簡介
本文件記錄如何在 **Ubuntu 24.04** 且為 **ARM64 架構**（如 NVIDIA DGX Spark / Grace Hopper 等）的環境下，正確安裝並執行 LM Studio。

主要解決 Ubuntu 24.04 加強了 AppArmor 權限限制，導致 Electron 應用程式（如 LM Studio）無法啟動沙箱 (Sandbox) 的問題。

> **環境資訊**
> - OS: Ubuntu 24.04 LTS
> - Architecture: ARM64 (AArch64)
> - Device: GIGABYTE AI TOP ATOM (NVIDIA DGX Spark)

## 🚀 安裝步驟

### 1. 下載 AppImage
前往 LM Studio 官網下載 Linux 版本。
**注意：** 務必確認下載的是 **ARM64** 版本，而非 x86_64。
- 檔案範例：`LM-Studio-0.3.36-1-arm64.AppImage`

### 2. 賦予執行權限
開啟終端機，切換到下載目錄並賦予檔案執行權限：

```bash
cd ~/Downloads  # 或 ~/下載
chmod +x LM-Studio-*-arm64.AppImage
```

### 3. 執行測試 (排除 Sandbox 錯誤)
在 Ubuntu 24.04 直接執行會出現 FATAL:sandbox/linux/suid/client/setuid_sandbox_host.cc 錯誤。 這是因為系統核心限制了未授權使用者的 namespace 操作。

解決方案： 啟動時加上 --no-sandbox 參數。

```bash
./LM-Studio-*-arm64.AppImage --no-sandbox
```
若能成功開啟視窗，代表環境沒問題。

### 4. 設定便捷啟動方式

為了避免每次都要開終端機打指令，你可以選擇建立 **Desktop Entry** 或設定 **Alias**。

#### 方法 1：建立 Desktop Entry (桌面捷徑)

**1. 建立設定檔**

```bash
nano ~/.local/share/applications/lm-studio.desktop
```

**2. 貼上以下內容**

請將 `Exec` 和 `Icon` 的路徑修改為你的實際路徑（`<your-username>` 請替換為實際使用者名稱）。

```ini
[Desktop Entry]
Name=LM Studio
Comment=Run Local LLMs
# 關鍵：必須加上 --no-sandbox 參數
Exec=/home/<your-username>/Downloads/LM-Studio-0.3.36-1-arm64.AppImage --no-sandbox
Icon=utilities-terminal
Type=Application
Categories=Development;Science;ArtificialIntelligence;
Terminal=false
StartupWMClass=LM Studio
```

**3. 更新權限與桌面資料庫**

```bash
chmod +x ~/.local/share/applications/lm-studio.desktop
update-desktop-database ~/.local/share/applications/
```

現在你可以在 Ubuntu 的「顯示應用程式」選單中找到 LM Studio 並直接點擊執行。

#### 方法 2：設定 Alias (終端機別名)

開啟 `.bashrc` 設定檔：

```bash
nano ~/.bashrc
```

在檔案最下面加入這一行（假設檔案在 `~/Downloads` 資料夾，若為中文環境請改為 `~/下載`）：

```bash
alias lmstudio='~/Downloads/LM-Studio-0.3.36-1-arm64.AppImage --no-sandbox'
```

存檔離開 (`Ctrl+O`, `Enter`, `Ctrl+X`)，然後讓設定生效：

```bash
source ~/.bashrc
```

以後只要在 Terminal 打 `lmstudio` 就會自動帶參數跑起來了。

---

## ⚠️ 資安與權限重要說明 (Security Notice)

**為什麼必須使用 `--no-sandbox`？**
這是針對 **Ubuntu 24.04** 核心安全策略（AppArmor User Namespace 限制）的必要權宜之計。由於 AppImage 格式未經過 apt/snap 安裝流程，無法自動註冊系統安全白名單 (AppArmor Profile)，導致預設沙箱啟動失敗。

**潛在風險：**
加上 `--no-sandbox` 參數意味著 LM Studio 將**不使用 Chrome 沙箱隔離機制**。
* 應用程式將以「一般處理程序」運行，擁有與執行者（當前使用者）完全相同的系統權限。
* 若應用程式本身遭駭或載入惡意程式碼，將能直接讀取/修改使用者的家目錄檔案 (`/home/<user>/`)。

**建議措施：**
1.  **環境限制：** 僅在受信任的內部環境（如本機 DGX / 內網開發機）使用此方式。
2.  **來源管控：** 請務必僅從 LM Studio 官方網站下載程式，並確保模型來源 (Hugging Face) 可信。
3.  **進階隔離：** 若未來需在對外服務或高敏感資料環境運行，建議改用 Docker 容器化部署或手動配置 AppArmor Profile 以確保隔離完整性。