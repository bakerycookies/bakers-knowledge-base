# CLI 效率優化：Alias 別名與自動化腳本

- **適用**：全端工程師、DevOps
- **目標**：透過自訂 Shell Alias 與自動化腳本，縮短冗長指令，提升終端機操作效率並實現跨機器快速部署。

## 第一階段：手動設定 (Manual Configuration)

我們可以透過修改 Shell 的設定檔，將常用的長指令對應成短指令 (Alias)，例如用 `aa` 取代 `npm run start:dev`。

### 1. 確認設定檔位置

*   **macOS (Zsh)**: `~/.zshrc`
*   **Linux (Bash)**: `~/.bashrc`

### 2. 編輯設定檔

以 macOS 為例：

```bash
nano ~/.zshrc
```

### 3. 加入自訂指令

請將以下內容貼在檔案**最下方**：

```bash
# 範例 1：用 'aa' 啟動開發伺服器
alias aa='npm run start:dev'

# 範例 2：用 'pull' 同步程式碼
alias pull='git pull origin main'

# 範例 3：進入專案並啟動 Docker
alias up='cd ~/my-project && docker-compose up -d'
```

> **語法結構**：`alias [自訂縮寫]='[原本的完整指令]'`

### 4. 套用設定 (Reload)

```bash
source ~/.zshrc
```

---

## 第二階段：自動化部署 (Automated Setup)

為了在多台機器或團隊成員間快速同步這些習慣，建議撰寫 Shell Script 來自動偵測環境並寫入設定。
本專案提供了一個範例腳本供參考：[configure_shell_aliases.sh](../../example-code/configure_shell_aliases.sh)。

### 1. 腳本內容範例 (`configure_shell_aliases.sh`)

```bash
#!/bin/bash

# 配置區域：定義 Alias 對應規則
# 格式為 "縮寫:完整指令"
TARGET_ALIASES=(
    "cc:claude"
    "c:clear"
)

COMMENT_HEADER="# === Custom Aliases (Auto Generated) ==="


# 1. 環境偵測程序
CURRENT_SHELL=$(basename "$SHELL")
OS_TYPE=$(uname)
OS_DISPLAY=$OS_TYPE

# 作業系統顯示名稱
if [[ "$OS_TYPE" == "Darwin" ]]; then
    OS_DISPLAY="macOS (Darwin)"
fi

echo " 偵測作業系統：$OS_DISPLAY"
echo " 偵測預設 Shell：$CURRENT_SHELL"

# 判定 Shell 設定檔路徑
if [[ "$OS_TYPE" == "Darwin" ]]; then
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        CONFIG_FILE="$HOME/.zshrc"
    elif [[ "$CURRENT_SHELL" == "bash" ]]; then
        CONFIG_FILE="$HOME/.bash_profile"
    else
        CONFIG_FILE="$HOME/.zshrc"
    fi
else
    # Linux 環境
    if [[ "$CURRENT_SHELL" == "zsh" ]]; then
        CONFIG_FILE="$HOME/.zshrc"
    else
        CONFIG_FILE="$HOME/.bashrc"
    fi
fi

echo " 目標設定檔：$CONFIG_FILE"
echo "------------------------------------------------"

# 寫入程序 (迴圈處理)

# 確保設定檔末尾包含換行符，防止內容拼接錯誤
if [ -s "$CONFIG_FILE" ] && [ "$(tail -c1 "$CONFIG_FILE" | wc -l)" -eq 0 ]; then
    echo "" >> "$CONFIG_FILE"
fi

# 若設定檔中尚未包含自訂 Alias 區塊，則寫入標頭
if ! grep -q "$COMMENT_HEADER" "$CONFIG_FILE"; then
    echo "" >> "$CONFIG_FILE"
    echo "$COMMENT_HEADER" >> "$CONFIG_FILE"
fi

# 開始逐一處理 Alias 設定
CHANGE_MADE=false

for item in "${TARGET_ALIASES[@]}"; do
    # 解析字串：冒號左側為 Alias 縮寫，右側為對應指令
    ALIAS_KEY="${item%%:*}"
    ALIAS_CMD="${item#*:}"

    # 執行檢查：搜尋 "alias 縮寫=" 以避免重複設定
    # 使用 grep 精確搜尋 alias key=，確保不會因指令內容相同但 Key 不同而造成誤判
    if grep -q "alias $ALIAS_KEY=" "$CONFIG_FILE"; then
        echo " [跳過] 指令 '$ALIAS_KEY' 已經存在。"
    else
        echo "alias $ALIAS_KEY='$ALIAS_CMD'" >> "$CONFIG_FILE"
        echo " [新增] alias $ALIAS_KEY='$ALIAS_CMD'"
        CHANGE_MADE=true
    fi
done

echo "------------------------------------------------"

if [ "$CHANGE_MADE" = true ]; then
    echo " [完成] 設定已更新！請執行以下指令以套用變更："
    echo "source $CONFIG_FILE"
else
    echo " [未變更] 所有指令皆已存在，無需更新。"
fi
```

### 2. 執行安裝

賦予腳本執行權限並執行：

```bash
chmod +x configure_shell_aliases.sh
./configure_shell_aliases.sh
```

### 3. 生效設定

依照腳本提示執行 source：

```bash
source ~/.zshrc  # 或 ~/.bashrc
```

---

## 第三階段：進階技巧 (Function)

如果你希望指令可以「接收參數」（例如：`aa 8080` 代表開在 8080 port），單純的 `alias` 做不到，必須改用 `function`。

**寫法範例** (同樣加在 `.zshrc` 或 `.bashrc`)：

```bash
# 輸入 'aa 3000' -> 自動執行 'npm run start -- --port=3000'
function aa() {
    if [ -z "$1" ]; then
        echo "⚠️  請輸入 Port 號，例如：aa 3000"
    else
        echo "🚀 正在 Port $1 啟動服務..."
        npm run start -- --port=$1
    fi
}
```