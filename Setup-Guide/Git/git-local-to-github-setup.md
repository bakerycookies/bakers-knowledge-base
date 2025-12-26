# Git - 將本地專案上傳至 GitHub 流程筆記

這篇筆記記錄如何將一個現有的本地專案 (Local Project) 初始化並上傳到 GitHub 新建立的倉庫 (Repository)。

## 1. 前置作業：檢查 .gitignore (非常重要！)

在執行 `git add` 之前，**務必**確認專案根目錄下有 `.gitignore`，避免將垃圾檔案或機敏資料傳上去。
特別是全端專案 (Django + React)，要檢查以下項目是否已被忽略：

* **系統檔:** `.DS_Store` (Mac)
* **Python/Django:** `__pycache__/`, `venv/`, `*.pyc`, `db.sqlite3`, `.env` (機敏資料絕對不能傳！)
* **Node/React:** `node_modules/`, `build/`, `npm-debug.log`

## 2. 操作步驟 (Terminal 指令)

切換到專案根目錄，依序執行：

1. 初始化 Git
```bash
git init
```

2. 加入所有檔案到暫存區 (Staging)
```bash
git add .
```

3. 提交版本 (Commit)
```bash
git commit -m "Initial commit"
```

4. 重新命名分支為 main (GitHub 預設規範)
```bash
git branch -M main
```

5. 設定遠端倉庫地址
(將 `<你的倉庫網址>` 換成實際 URL，例如: `https://github.com/bakerycookies/xxx.git`)
```bash
git remote add origin <你的倉庫網址>
```

6. 推送到遠端 (第一次推送需加 -u 設定上游)
```bash
git push -u origin main
```

## 3. 常見狀況排除

### 狀況 A：`remote origin already exists`

如果執行 `git remote add` 時出現此錯誤，代表這個資料夾之前已經綁定過其他遠端位置。

**解法：**

先移除舊的 origin
```bash
git remote remove origin
```

再重新加入新的
```bash
git remote add origin <你的新倉庫網址>
```

### 狀況 B：修改了 .gitignore 但檔案還是被追蹤

如果在 `git add .` 之後才發現漏寫 `.gitignore`，檔案已經被 Git 紀錄了。

**解法：**

清除本地的暫存區 (不會刪除實體檔案)
```bash
git rm -r --cached .
```

重新加入檔案 (這時 Git 才會重新讀取 .gitignore)
```bash
git add .
```

提交修正
```bash
git commit -m "Fix .gitignore"
```

## 4. 參考資源

* [GitHub 官方文件](https://docs.github.com/en/get-started)