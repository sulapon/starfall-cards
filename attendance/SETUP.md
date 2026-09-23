# 員工差勤表 — 雲端部署說明

前端：`index.html`（純靜態，可放任何 GitHub repo → GitHub Pages）
後端：`Code.gs`（Google Apps Script）＋ Google 試算表（共用資料庫）
假日：台灣行政院人事行政總處辦公日曆，經 `cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar` 自動按年抓取，免維護。

## 功能
- 病假 / 休假 / 特休 / 事假 / 補休 / 公差（公差必填「出差地點」）
- 月曆檢視（國定假日紅底＋假單標籤）、明細、每月統計、員工管理
- 撞國定假日自動警告；匯出 CSV；手機可用；無後端時自動降級為本機試用模式

## 一、建立共用資料庫（5 分鐘）
1. 新增 Google 試算表（例：`員工差勤DB`），記下網址。
2. 選單 擴充功能 → Apps Script，把 `Code.gs` 全文貼上覆蓋，存檔。
3. 先手動在試算表建兩張工作表（或直接跑一次後端會自動建）：
   - `employees` 首列：`name | dept`
   - `records` 首列：`id | name | type | from | to | trip | note`
4. Apps Script 右上「部署」→「新增部署作業」→ 類型選「網頁應用程式」：
   - 執行身分：**我**
   - 存取權：**所有人**（含匿名，否則前端 POST 會 403）
   - 部署 → 複製 **Web App 網址**（`/exec` 結尾）。

## 二、前端上 GitHub Pages
1. 把 `index.html` 放進你的 repo 子目錄（例：`attendance/index.html`），push 到 `main`。
2. repo Settings → Pages → 來源選 `main` 分支，開頁驗證 200。
3. 手機/電腦開 Pages 網址 → ⚙️ 連線設定 → 貼上 Web App 網址 → 儲存連線。
4. 之後所有裝置共用同一份試算表，即時同步。

## 三、假日自動更新原理
- 前端按目前年份 `fetch https://cdn.jsdelivr.net/gh/ruyut/TaiwanCalendar/data/{year}.json`，12 月自動預抓下一年。
- 資料源整理自政府資料開放平台「中華民國政府行政機關辦公日曆表」（每年約 6 月公告次年）。
- 若該 repo 尚未更新次年，前端顯示空假日，不影響既有假單。

## 試算表欄位說明
| 表 | 欄位 | 說明 |
|---|---|---|
| employees | name, dept | name 為 key，不可重複 |
| records | id, name, type, from, to, trip, note | type 限 病假/休假/特休/事假/公差/補休；trip 僅公差必填；日期 YYYY-MM-DD |
