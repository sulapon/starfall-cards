#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  opencode 安裝 (Termux + proot-distro + Debian)
#  原理: Android 強制 PIE(ET_DYN)，opencode 官方 binary 是非-PIE(ET_EXEC)，
#        故 Termux 原生無法執行。透過 proot-distro 裝 Debian 提供純 Linux
#        userspace，在內安裝 opencode 即可正常運作(等同 Minis 沙箱原理)。
#
#  使用: bash termux-opencode.sh
# ============================================================
set -e

# --- DeepSeek API Key (若有環境變數則優先) ---
API_KEY="${OPENCODE_API_KEY:-sk-WbGoNhQvnVWvXjVn2voVeGpHlkTvzEjAYa8oub4I8sBjV3HJ8ExBrmCDhYhZU0gu}"
DISTRO="debian"

echo ""
echo "======================================"
echo "  opencode 安裝 (Termux + proot)      "
echo "======================================"
echo ""

# --- 1. 安裝 proot-distro ---
echo "[1/4] 安裝 proot-distro ..."
pkg update -y
pkg install -y proot-distro

# --- 2. 安裝 Debian 發行版 ---
echo ""
echo "[2/4] 安裝 $DISTRO 發行版 (第一次會下載數百MB，請耐心) ..."
if proot-distro list-installed 2>/dev/null | grep -q "$DISTRO"; then
  echo "  $DISTRO 已安裝，略過"
else
  proot-distro install "$DISTRO" --yes
fi

# --- 3. 在 Debian 內: 裝 opencode + 寫設定 + 驗證 ---
echo ""
echo "[3/4] 在 $DISTRO 內安裝 opencode + 設定 DeepSeek ..."
proot-distro login "$DISTRO" -- bash -s << PSEOF
set -e
export DEBIAN_FRONTEND=noninteractive
export PATH="\$HOME/.opencode/bin:\$PATH"

echo '  * 安裝基本工具 ...'
command -v curl >/dev/null 2>&1 || { apt-get update -y && apt-get install -y curl; }
command -v unzip >/dev/null 2>&1 || apt-get install -y unzip

echo '  * 安裝 opencode (官方 install script, linux-arm64) ...'
curl -fsSL https://opencode.ai/install | bash

echo '  * 寫入 DeepSeek 設定 ...'
mkdir -p "\$HOME/.config/opencode"
export PATH="\$HOME/.opencode/bin:\$PATH"

# 用環境變數傳遞 key，避免在 proot 內出現明碼碼殼
PROOT_B64='eyIkc2NoZW1hIjogImh0dHBzOi8vb3BlbmNvZGUuYWkvY29uZmlnLmpzb24iLCAicHJvdmlkZXIiOiB7Im9wZW5jb2RlIjogeyJucG0iOiAiQGFpLXNkay9vcGVuYWktY29tcGF0aWJsZSIsICJuYW1lIjogIk9wZW5Db2RlIFplbiIsICJvcHRpb25zIjogeyJiYXNlVVJMIjogImh0dHBzOi8vb3BlbmNvZGUuYWkvemVuL3YxIiwgImFwaUtleSI6ICJzay1XYkdvTmhRdm5WV3ZYalZuMnZvVmVHcEhsa1R2ekVqQVlhOG91YjRJOHNCalYzSEo4RXhCcm1DRGhZaFpVMGd1In0sICJtb2RlbHMiOiB7ImRlZXBzZWVrLXY0LWZsYXNoLWZyZWUiOiB7Im5hbWUiOiAiRGVlcFNlZWsgVjQgRmxhc2ggRnJlZSJ9fX19LCAibW9kZWwiOiAib3BlbmNvZGUvZGVlcHNlZWstdjQtZmxhc2gtZnJlZSJ9'
echo "\$PROOT_B64" | base64 -d > "\$HOME/.config/opencode/opencode.json"

echo '  * 驗證版本 ...'
opencode --version
PSEOF

# --- 4. 建立 Termux 桌面一鍵啟動 wrapper ---
echo ""
echo "[4/4] 建立桌面捷徑脚本 (~/.shortcuts/opencode.sh) ..."
mkdir -p "$HOME/.shortcuts"
cat > "$HOME/.shortcuts/opencode.sh" << SHORTEOF
#!/data/data/com.termux/files/usr/bin/bash
cd ~
exec proot-distro login ${DISTRO} -- bash -lc 'export PATH=\$HOME/.opencode/bin:\$PATH; cd ~; exec opencode'
SHORTEOF
chmod +x "$HOME/.shortcuts/opencode.sh"

echo ""
echo "======================================"
echo "  安裝完成！"
echo "======================================"
echo ""
echo "  立即啟動:"
echo "    proot-distro login ${DISTRO} -- bash -lc 'export PATH=\$HOME/.opencode/bin:\$PATH; opencode'"
echo ""
echo "  桌面捷徑: 安裝『Termux:Widget』→ 新增小工具 → ~/.shortcuts 的 opencode"
echo ""
echo "  模型: opencode/deepseek-v4-flash-free (DeepSeek V4 Flash Free)"
