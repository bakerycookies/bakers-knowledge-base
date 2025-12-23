# macOS 終端機環境建置：iTerm2 + Oh My Zsh 終極指南

- **適用**：全端工程師、MIS
- **目標**：從零打造高效率、視覺化的終端機開發環境 (Homebrew -> iTerm2 -> Zsh -> Plugins)。

## 第一階段：基礎建設 (安裝核心工具)

建議先使用 Mac 原生終端機 (Terminal) 執行第 1 步，裝好 iTerm2 後就切換過去操作。

### 1. 安裝 Homebrew (套件管理神器)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

> ⚠️ **注意**： 安裝跑完後，**務必**執行終端機畫面上提示的 `echo` 指令來設定環境變數 (PATH)，否則 `brew` 指令會找不到。

### 2. 安裝 iTerm2 (取代原生終端機)

```bash
brew install --cask iterm2
```

**從這一步開始，請關閉原生終端機，打開 iTerm2 繼續操作。**

---

## 第二階段：Shell 美化框架

### 3. 安裝 Oh My Zsh

```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```

---

## 第三階段：安裝外掛 (提升開發效率)

我們需要先將外掛的程式碼下載 (Clone) 到 Oh My Zsh 的指定目錄。

### 4. 下載自動建議外掛 (Auto Suggestions)
*輸入指令時，會以淺灰色提示曾輸入過的指令。*

```bash
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
```

### 5. 下載語法高亮外掛 (Syntax Highlighting)
*指令正確顯示綠色，錯誤顯示紅色。*

```bash
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
```

---

## 第四階段：設定檔配置 (關鍵步驟)

這是讓外掛生效的關鍵。

### 6. 編輯 .zshrc 設定檔

```bash
nano ~/.zshrc
```

### 7. 修改 Plugins 參數

在檔案中找到 `plugins=(git)` 這一行，手動修改成以下內容：
(**注意是用空白鍵分隔，嚴禁使用逗號**)

```bash
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)
```

### 8. 存檔與離開 nano
1. 按 `Ctrl + O` (寫入)。
2. 按 `Enter` (確認)。
3. 按 `Ctrl + X` (離開)。

### 9. 重新載入設定

```bash
source ~/.zshrc
```
*(如果這行執行後沒有報錯，就代表語法正確)*

---

## 第五階段：字型優化 (避免亂碼)

為了讓終端機能顯示特殊的 Icon，需要安裝 Nerd Font。

### 10. 安裝 Hack Nerd Font

```bash
brew install --cask font-hack-nerd-font
```

### 11. 修改 iTerm2 設定
1. 打開 iTerm2 設定 (`Cmd + ,`) -> **Profiles** -> **Text**。
2. 在 **Font** 下拉選單中選擇 `Hack Nerd Font`。

---

## 第六階段：驗收測試 (MIS 的 QA 時間)

請執行以下三個動作，確認環境完美運作：

1.  **視覺檢查**：
    你的提示字元應該不再是單調的 `bash$`，可能有綠色箭頭或不同顏色的路徑顯示。

2.  **高亮測試 (Syntax Highlighting)**：
    *   輸入 `git` -> 字體要是**綠色** (代表指令存在)。
    *   輸入 `gittttt` -> 字體要是**紅色** (代表指令不存在)。

3.  **智慧補全測試 (Auto Suggestions)**：
    *   輸入 `sou` -> 應該會看到後面有淺灰色的 `rce ~/.zshrc` 浮現。
    *   按 **右方向鍵 (→)** -> 應該會自動補完這行指令。

---
如果以上測試皆通過，恭喜您，您的全端開發環境已經就緒！這套高效率的終端機環境將能讓您在開發 React 或 Django 專案時更加得心應手。
