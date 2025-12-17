# 🛠️ macOS Python 環境重建與接管 SOP (Clean Install Guide)

- **適用**：全端工程師 / MIS
- **目標**：移除官網安裝的 Python (pkg)，改用 Homebrew 管理 Python 3.12，並修復路徑優先權。
- **前提**：需有管理員權限 (sudo)，且已安裝 Homebrew。

## 第 1 階段：徹底移除官網 Python (Exorcism)

⚠️ **注意**：以下指令中的 `3.xx` 請替換為你要移除的實際版本號（例如 `3.11` 或 `3.12`）。

1. **刪除 Python 核心框架**：
```bash
sudo rm -rf /Library/Frameworks/Python.framework/Versions/3.xx
```

2. **刪除應用程式目錄**：
```bash
sudo rm -rf "/Applications/Python 3.xx"
```

3. **清理 /usr/local/bin 殘留的 Symlink： 這步建議分兩段做，先檢查再刪除，以免誤殺**。

- (A) 先列出會被刪除的連結（Dry Run）：
``` bash
ls -l /usr/local/bin | grep '3.xx'
```
- (B) 確認無誤後，執行刪除：
```bash
ls -l /usr/local/bin | grep '3.xx' | awk '{print $9}' | xargs -I {} sudo rm /usr/local/bin/{}
```

4. **移除 Shell 設定裡的 PATH**：
```bash
open ~/.zprofile
open ~/.zshrc
```
> 動作：找到包含 Setting PATH for Python 3.xx 的區塊，整段刪除後存檔。

## 第 2 階段：Homebrew 安裝與設定 (Installation)
1) 安裝 Python 3.12：
```bash
brew update
brew install python@3.12
```

2) 建立強制連結（確保打 python3 時系統優先使用 3.12）： Homebrew 更新時可能會重置此連結，若失效請重新執行。
```bash
ln -sf /opt/homebrew/bin/python3.12 /opt/homebrew/bin/python3
ln -sf /opt/homebrew/bin/pip3.12 /opt/homebrew/bin/pip3
```

## 第 3 階段：修正 Zsh 記憶與環境 (Configuration)
1) 確保 Homebrew 路徑優先：
```bash
# 確保這行在 .zshrc 的最下方，或是比 export PATH 晚執行
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
```

2) 重新載入並清除指令快取：
```bash
source ~/.zshrc
hash -r
```

## 第 4 階段：最終驗收 (QC Check)
依序執行並比對期望結果。

1) 檢查 Python 執行檔路徑：
```bash
which python3
```
✅ 期望：`/opt/homebrew/bin/python3`

2) 檢查 Pip 執行檔路徑：
```bash
which pip3
```
✅ 期望：`/opt/homebrew/bin/pip3`

3) 檢查版本連動性：
```bash
pip3 --version
```
✅ 期望：輸出最後需帶 `(python 3.12)`。

## 💡 開發者小筆記 (Dev Note)
從 Python 3.11+ 開始，為避免破壞系統環境，pip 預設會阻擋全域安裝 (PEP 668)。

開發專案：請務必建立虛擬環境 (python3 -m venv venv)。

安裝全域工具 (如 CLI 工具)：建議改用 brew install 或 pipx install。