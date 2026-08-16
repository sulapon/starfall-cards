# 🤖 GitHub 遊戲中心 — AI Agent 完整交接文件
> 提供給任何需要接手此專案、建立新遊戲並自動上傳 GitHub Pages 的 AI Agent。

---

## ⚙️ 一、所有帳號 / Token / Key 設定總表

> ⚠️ 安全規則：以下所有 Token 一律以「環境變數」方式引用，**不得將明文寫進任何檔案、Commit 或對話記錄**。明文只在第一次手動設定時輸入一次到環境變數。

| 用途 | 環境變數名稱 | 狀態 | 如何取得 / 設定 |
|---|---|---|---|
| GitHub 上傳權杖 | `GITHUB_TOKEN` | ✅ 已設定 | repo `starfall-cards` 擁有者 sulapon 的個人存取權杖(PAT)，scope 需含 `repo` |
| OpenCode Zen API | `OPENCODE_TOKEN` | ✅ 已設定 | opencode.ai 免費 API key |
| Gemini 視覺模組 | `GEMINI_API_KEY_SULAKEN02` | ✅ 已設定 | Google AI Studio 免費 key |
| Gemini 輪換 key 2 | `GEMINI_KEY1` | ⛔ 未設定 | 可選，用於 Gemini 限流時多 key 輪換 |
| Gemini 輪換 key 3 | `GEMINI_KEY2` | ⛔ 未設定 | 可選 |
| Gemini 輪換 key 4 | `GEMINI_KEY3` | ⛔ 未設定 | 可選 |
| Gemini 輪換 key 5 | `GEMINI_KEY4` | ⛔ 未設定 | 可選 |
| Gemini 輪換 key 6 | `GEMINI_KEY5` | ⛔ 未設定 | 可選 |

> **環境變數設定方法**（對不熟悉設定的 Agent）：
> Minis App：`Settings → Environments` → 建立變數。
> 命令列：`export GITHUB_TOKEN="..."`（不寫入任何檔案）。

### GitHub 認證資訊
- **帳號 (login)**：`sulapon`
- **Repo 名稱**：`starfall-cards`
- **公開網址**：https://sulapon.github.io/starfall-cards/
- **API-Host**：https://api.github.com
- **Push 用 Remote URL 格式**（勿寫死 token）：
  ```
  https://sulapon:${GITHUB_TOKEN}@github.com/sulapon/starfall-cards.git
  ```

---

## 🗂️ 二、GitHub 倉庫真實結構（截至 2026-08-16）

```
starfall-cards/
├── index.html              # 遊戲中心主頁（顯示所有遊戲卡片）
├── manifest.json           # PWA 清單
├── sw.js                   # Service Worker（快取）
├── icon-192.png / icon-512.png
├── .nojekyll               # 停用 Jekyll
├── astra-survivor/         # 星穹守護者（生存）
│   └── index.html
├── card-game/              # 星穹牌局（卡牌）
│   └── index.html
├── chronicle-of-destiny/   # 命運編年史
│   └── index.html
├── merge-defense/          # 星際合成防線（合成塔防）
│   └── index.html
├── opencode-launcher/      # opencode 安裝器
│   └── index.html
└── 通訊模擬/                # 通訊模擬遊戲
    └── index.html
```
> 新增遊戲後，**必須**在根目錄 `index.html` 的 `<div class="grid">` 區塊內新增一張 `<a class="card" href="新遊戲資料夾名/">` 卡片。

### 📍 線上網址總表（各專案對應的 Pages 網址）

| 子目錄 | 線上網址 |
|---|---|
| 根目錄（遊戲中心） | https://sulapon.github.io/starfall-cards/ |
| `merge-defense/` | https://sulapon.github.io/starfall-cards/merge-defense/ |
| `astra-survivor/` | https://sulapon.github.io/starfall-cards/astra-survivor/ |
| `card-game/` | https://sulapon.github.io/starfall-cards/card-game/ |
| `chronicle-of-destiny/` | https://sulapon.github.io/starfall-cards/chronicle-of-destiny/ |
| `zen-health/` | https://sulapon.github.io/starfall-cards/zen-health/ |
| `opencode-launcher/` | https://sulapon.github.io/starfall-cards/opencode-launcher/ |
| `通訊模擬/`（中文需 URL 編碼） | https://sulapon.github.io/starfall-cards/%E9%80%9A%E8%A8%8A%E6%A8%A1%E6%93%AC/ |

---

## 🛠️ 三、Android / 手機觸控遊戲開發守則

> 歸納自過往開發「星際合成防線」「星穹守護者」的實戰踩坑，遇到手機觸控問題務必遵守：

### 1. 座標轉換校正（最常見 bug）
Canvas 被 CSS 撐大時，觸控/滑鼠座標必須減去 `getBoundingClientRect()` 偏移，否則會錯位數個格子：
```javascript
const rect = canvas.getBoundingClientRect();
const scaleX = canvas.width / rect.width;
const scaleY = canvas.height / rect.height;
const gameX = (clientX - rect.left) * scaleX;
const gameY = (clientY - rect.top) * scaleY;
```

### 2. 觸控拖曳鎖定三寶
1. **CSS `touch-action: none`** — 加在 `stage`、`buildbar`、可拖曳塔身上，避免瀏覽器捲動手勢搶走拖曳。
2. **監聽 `pointercancel`** — 拖曳中斷時重置狀態，**否則觸控會永久鎖死無法再拖**（舊版 bug）。
3. **`setPointerCapture(pointerId)`** — 在 `pointerdown` 時鎖定手勢目標。

### 3. 拖曳源容器避免 `overflow-x: auto`
手機瀏覽器會優先將這類容器當作「可橫向捲動區」搶走拖曳手勢。改用 `flex-wrap: wrap` 換行排版更安全。

### 4. rAF 背景停擺
手機切去背景或換分頁，`requestAnimationFrame` 會停。加一個 `setInterval`（約 200ms）檢查上次 rAF 時間戳，若停滯則以固定 dt 推近剩餘幀數。

### 5. Canvas 繪製主循環防黑屏
`Render.draw()` 內任何一行 `undefined` 呼叫都會中斷整段繪製變成黑屏。**整個 draw 用 `try...catch` 包住**，並在繪製前做守衛判斷。

### 6. 觸發事件用 PointerEvent
優先使用 PointerEvent（觸控+滑鼠統一），並以 `passive: false` 註冊 `touchstart` 作雙保險。

---

## 🚀 四、自動化上傳 GitHub Pages SOP（禁 token 明文）

### Step 1 — Clone 或更新 repo
```bash
cd /your/workspace
git clone "https://sulapon:${GITHUB_TOKEN}@github.com/sulapon/starfall-cards.git"
cd starfall-cards
```

### Step 2 — 建立新遊戲
1. 建立子資料夾 `新遊戲名/`，放入 `index.html`。
2. 在根目錄 `index.html` 的 `<div class="grid">` 內新增卡片。
3. 資源路徑一律用**相對路徑**（`href="新遊戲名/"`、`src="assets/a.png"`），確保在 GitHub Pages 子目錄下正常。

### Step 3 — Commit & Push
```bash
cd /your/workspace/starfall-cards
git add .
git commit -m "feat: 新增遊戲《名稱》並更新入口"
git push "https://sulapon:${GITHUB_TOKEN}@github.com/sulapon/starfall-cards.git" main
```

### Step 4 — 部署驗證
- 瀏覽 `https://sulapon.github.io/starfall-cards/` 確認新卡片出現。
- 附版本參數繞過快取：`https://sulapon.github.io/starfall-cards/新遊戲/?v=1.0.1`
- GitHub Pages 有時延遲 1~2 分鐘更新，可先等再驗證。

---

## ✅ 五、給其他 Agent 的最終檢查清單

- [ ] `$GITHUB_TOKEN` 已在環境變數且有效（`curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user`）。
- [ ] 所有遊戲資源使用相對路徑。
- [ ] Canvas 座標轉換已用 `getBoundingClientRect` 校正。
- [ ] 已處理 `pointercancel`、`setPointerCapture`、`touch-action`。
- [ ] 畫布 draw 主循環有 try...catch。
- [ ] Commit message 清楚。
- [ ] Push 用 `sulapon:${GITHUB_TOKEN}@...`，**不寫死明文 token**。
- [ ] Push 後已驗證 Pages 正常。

---

## 🌐 六、部署後「開啟網頁」

驗證 Pages 回 HTTP 200 後，替使用者開啟對應線上網址：

| 情境 | 開啟方式 |
|---|---|
| 電腦 agent（macOS） | `open https://sulapon.github.io/starfall-cards/xxx/` |
| 電腦 agent（Linux） | `xdg-open https://sulapon.github.io/starfall-cards/xxx/` |
| 電腦 agent（Windows） | `start https://sulapon.github.io/starfall-cards/xxx/` |
| 手機 Minis agent | `minis-open https://sulapon.github.io/starfall-cards/xxx/`（app 內預覽）或直接給使用者 Markdown 連結 |

**注意**：GitHub Pages 有 CDN 快取，剛 push 完的前 1–2 分鐘可能讀到舊版。驗證網址可加參數繞過：`https://sulapon.github.io/starfall-cards/xxx/?v=1.0.1`。
```
