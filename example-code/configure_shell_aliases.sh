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
