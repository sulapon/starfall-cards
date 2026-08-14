#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  opencode 安裝 (Termux 原生) — guysoft/opencode-termux
#  官方 opencode binary 是非-PIE(ET_EXEC)，Android 強制 PIE 會拒絕執行。
#  guysoft 專案交叉編譯了 PIE(ET_DYN) 的 Android aarch64 版本，
#  只要 LD_PRELOAD libtagfix.so + 搭配 libc++_shared.so 即可在 Termux 直跑。
#
#  使用: bash termux-opencode.sh
# ============================================================
set -e

# --- DeepSeek API Key ---
API_KEY="${OPENCODE_API_KEY:-sk-WbGoNhQvnVWvXjVn2voVeGpHlkTvzEjAYa8oub4I8sBjV3HJ8ExBrmCDhYhZU0gu}"

REPO="guysoft/opencode-termux"
LATEST="v0.2.1"
IMGVERSION="1.17.9"
URL="https://github.com/${REPO}/releases/download/${LATEST}/opencode-${IMGVERSION}-android-aarch64.zip"
INSTALL_DIR="$HOME/.opencode-termux"

echo ""
echo "======================================"
echo "  opencode 安裝 (Termux 原生版)       "
echo "======================================"
echo ""

# --- 1. 下載 & 解壓 ---
echo "[1/3] 下載 opencode-android-aarch64 (版本 $IMGVERSION) ..."
mkdir -p "$INSTALL_DIR"
ZIP="$HOME/opencode-android.zip"
curl -fsSL -o "$ZIP" "$URL"
echo "  解壓到 $INSTALL_DIR ..."
unzip -o "$ZIP" -d "$INSTALL_DIR" >/dev/null
chmod +x "$INSTALL_DIR/opencode" "$INSTALL_DIR/opencode.bin" 2>/dev/null || true
rm -f "$ZIP"

# --- 2. 寫 DeepSeek 設定 (OpenCode Zen provider) ---
echo ""
echo "[2/3] 寫入 DeepSeek V4 Flash Free 設定 ..."
mkdir -p "$HOME/.config/opencode"
cat > "$HOME/.config/opencode/opencode.json" << JSONEOF
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

# --- 3. 建立 PATH 與桌面捷徑 ---
echo ""
echo "[3/3] 建立啟動腳本與桌面捷徑 ..."
# 建立 ~/.local/bin/opencode 軟連結 (讓加進 PATH 即可用)
mkdir -p "$HOME/.local/bin"
ln -sf "$INSTALL_DIR/opencode" "$HOME/.local/bin/opencode"

# 確保 PATH 含 ~/.local/bin
for rc in "$HOME/.bashrc" "$HOME/.profile"; do
  [ -f "$rc" ] && grep -q '.local/bin' "$rc" || echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$rc" 2>/dev/null
done

# 桌面捷徑腳本
mkdir -p "$HOME/.shortcuts"
cat > "$HOME/.shortcuts/opencode.sh" << SHORTEOF
#!/data/data/com.termux/files/usr/bin/bash
cd ~
exec "$INSTALL_DIR/opencode"
SHORTEOF
chmod +x "$HOME/.shortcuts/opencode.sh"

# --- 驗證 ---
echo ""
echo "  驗證版本 ..."
export PATH="$HOME/.local/bin:$PATH"
"$INSTALL_DIR/opencode" --version && echo "  ✅ opencode 安裝成功 (Termux 原生版)"

echo ""
echo "======================================"
echo "  安裝完成！"
echo "======================================"
echo ""
echo "  啟動:  直接在 Termux 輸入  opencode"
echo "  若 opencode 不在 PATH: $HOME/.local/bin/opencode"
echo ""
echo "  桌面捷徑: 安裝『Termux:Widget』→ 新增小工具 → ~/.shortcuts 的 opencode"
echo ""
echo "  模型: opencode/deepseek-v4-flash-free (DeepSeek V4 Flash Free, 免費)"
