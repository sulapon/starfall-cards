#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
#  opencode 安裝 (Termux + proot-distro + Alpine)
#  原理: Android 強制 PIE(ET_DYN)，opencode 官方 binary 是非-PIE(ET_EXEC)，
#        故 Termux 原生無法執行。透過 proot-distro 裝 Alpine 提供純 Linux
#        userspace，在內安裝 opencode 即可正常運作(等同 Minis 沙箱原理)。
#
#  使用: bash termux-opencode.sh
# ============================================================
set -e

# --- DeepSeek API Key (若有環境變數則優先) ---
API_KEY="${OPENCODE_API_KEY:-sk-WbGoNhQvnVWvXjVn2voVeGpHlkTvzEjAYa8oub4I8sBjV3HJ8ExBrmCDhYhZU0gu}"
DISTRO="alpine"

echo ""
echo "======================================"
echo "  opencode 安裝 (Termux + proot)      "
echo "======================================"
echo ""

# --- 1. 安裝 proot-distro ---
echo "[1/4] 安裝 proot-distro ..."
pkg update -y
pkg install -y proot-distro

# --- 2. 安裝 Alpine 發行版 (minirootfs 直接下載, 最小最快) ---
# 選用 Alpine 主因: Minis 沙箱即為 Alpine+proot+opencode(成功實證)，
# opencode 官方提供 alpine-musl 版 binary。rootfs 僅數MB，開機快。
echo ""
echo "[2/4] 下載並安裝 Alpine minirootfs ..."
ALPINE_VER="3.21.3"
ROOTFS_URL="https://dl-cdn.alpinelinux.org/alpine/v3.21/releases/aarch64/alpine-minirootfs-${ALPINE_VER}-aarch64.tar.gz"
ROOTFS_FILE="$HOME/apln-rootfs.tar.gz"
echo "  下載 $ALPINE_VER rootfs ..."
curl -fsSL "$ROOTFS_URL" -o "$ROOTFS_FILE"
proot-distro install -n alpine "$ROOTFS_FILE"
rm -f "$ROOTFS_FILE"

# --- 3. 在 Alpine 內: 裝 opencode + 寫設定 + 驗證 ---
echo ""
echo "[3/4] 在 $DISTRO 內安裝 opencode + 設定 DeepSeek ..."
proot-distro login "$DISTRO" -- sh -s << PSEOF
set -e
export PATH="\$HOME/.opencode/bin:\$PATH"

echo '  * 更新 apk & 安裝 curl '
apk update >/dev/null 2>&1 || true
command -v curl >/dev/null 2>&1 || apk add curl

echo '  * 安裝 opencode (官方 install script, alpine-musl) '
curl -fsSL https://opencode.ai/install | sh

echo '  * 寫入 DeepSeek 設定 '
mkdir -p "\$HOME/.config/opencode"
export PATH="\$HOME/.opencode/bin:\$PATH"

PROOT_B64='eyIkc2NoZW1hIjogImh0dHBzOi8vb3BlbmNvZGUuYWkvY29uZmlnLmpzb24iLCAicHJvdmlkZXIiOiB7Im9wZW5jb2RlIjogeyJucG0iOiAiQGFpLXNkay9vcGVuYWktY29tcGF0aWJsZSIsICJuYW1lIjogIk9wZW5Db2RlIFplbiIsICJvcHRpb25zIjogeyJiYXNlVVJMIjogImh0dHBzOi8vb3BlbmNvZGUuYWkvemVuL3YxIiwgImFwaUtleSI6ICJzay1XYkdvTmhRdm5WV3ZYalZuMnZvVmVHcEhsa1R2ekVqQVlhOG91YjRJOHNCalYzSEo4RXhCcm1DRGhZaFpVMGd1In0sICJtb2RlbHMiOiB7ImRlZXBzZWVrLXY0LWZsYXNoLWZyZWUiOiB7Im5hbWUiOiAiRGVlcFNlZWsgVjQgRmxhc2ggRnJlZSJ9fX19LCAibW9kZWwiOiAib3BlbmNvZGUvZGVlcHNlZWstdjQtZmxhc2gtZnJlZSJ9'
echo "\$PROOT_B64" | base64 -d > "\$HOME/.config/opencode/opencode.json"

echo '  * 驗證版本 '
opencode --version
PSEOF

# --- 4. 建立 Termux 桌面一鍵啟動 wrapper ---
echo ""
echo "[4/4] 建立桌面捷徑脚本 (~/.shortcuts/opencode.sh) ..."
mkdir -p "$HOME/.shortcuts"
cat > "$HOME/.shortcuts/opencode.sh" << SHORTEOF
#!/data/data/com.termux/files/usr/bin/bash
cd ~
exec proot-distro login ${DISTRO} -- sh -lc 'export PATH=\$HOME/.opencode/bin:\$PATH; cd ~; exec opencode'
SHORTEOF
chmod +x "$HOME/.shortcuts/opencode.sh"

echo ""
echo "======================================"
echo "  安裝完成！"
echo "======================================"
echo ""
echo "  立即啟動:"
echo "    proot-distro login ${DISTRO} -- sh -lc 'export PATH=\$HOME/.opencode/bin:\$PATH; opencode'"
echo ""
echo "  桌面捷徑: 安裝『Termux:Widget』→ 新增小工具 → ~/.shortcuts 的 opencode"
echo ""
echo "  模型: opencode/deepseek-v4-flash-free (DeepSeek V4 Flash Free)"
