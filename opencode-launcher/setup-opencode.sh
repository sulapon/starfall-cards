#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  opencode 一鍵安裝腳本 (Termux)
#  功能: 安裝 opencode + 對接 DeepSeek V4 Flash Free + 桌面捷徑
#  執行: bash setup-opencode.sh
# ============================================================
set -e

echo ""
echo "======================================"
echo "  opencode 安裝程式"
echo "======================================"

# --- 金鑰 ----
# 從本檔同一個地方設定。建議改用環境變數，避免金鑰躺在設定檔理。
# 若已用環境變數 OPENCODE_API_KEY，就不需改下面這行。
API_KEY="${OPENCODE_API_KEY:-sk-WbGoNhQvnVWvXjVn2voVeGpHlkTvzEjAYa8oub4I8sBjV3HJ8ExBrmCDhYhZU0gu}"

# --- 1. 更新 & 安裝必要套件 ---
echo ""
echo "[1/5] 更新套件 & 安裝 nodejs/git/termux-tools ..."
pkg update -y
pkg install -y nodejs-lts git termux-tools termux-api 2>/dev/null || \
  pkg install -y nodejs-lts git termux-tools

# --- 2. 安裝 opencode ---
echo ""
echo "[2/5] 安裝 opencode-ai (npm 全域) ..."
npm install -g opencode-ai

# --- 3. 寫 opencode 設定檔 ---
echo ""
echo "[3/5] 設定 DeepSeek V4 Flash Free ..."
mkdir -p ~/.config/opencode
cat > ~/.config/opencode/opencode.json << JSONEOF
{
  "\$schema": "https://opencode.ai/config.json",
  "provider": {
    "opencode": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "OpenCode Zen",
      "options": {
        "baseURL": "https://opencode.ai/zen/v1",
        "apiKey": "${API_KEY}"
      },
      "models": {
        "deepseek-v4-flash-free": {
          "name": "DeepSeek V4 Flash Free"
        }
      }
    }
  },
  "model": "opencode/deepseek-v4-flash-free"
}
JSONEOF

# --- 4. 建立桌面捷徑腳本 (Termux:Widget) ---
echo ""
echo "[4/5] 建立桌面捷徑腳本 (~/.shortcuts/opencode.sh) ..."
mkdir -p ~/.shortcuts
cat > ~/.shortcuts/opencode.sh << 'MOBILEEOF'
#!/data/data/com.termux/files/usr/bin/bash
cd ~
exec opencode
MOBILEEOF
chmod +x ~/.shortcuts/opencode.sh ~/.shortcuts/opencode.sh

# --- 5. 驗證 ---
echo ""
echo "[5/5] 驗證安裝 ..."
V=$(opencode --version 2>/dev/null || echo "尚未就緒")
echo "  opencode 版本: $V"

echo ""
echo "======================================"
echo "  安裝完成！"
echo "======================================"
echo ""
echo "  立即啟動:  在 Termux 輸入  opencode  然後按 Enter"
echo "  桌面捷徑:  需安裝『Termux:Widget』App，拉一個桌面小工具"
echo "             加入桌面的 .shortcuts → opencode"
echo ""
echo "  模型: deepseek-v4-flash-free (DeepSeek V4 Flash Free)"
