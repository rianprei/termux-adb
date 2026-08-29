#!/data/data/com.termux/files/usr/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
step()  { echo -e "${BLUE}[>]${NC} $1"; }

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

echo
info "Termux ADB Unificado — desinstalador v4.0.0"
echo

step "Removendo pacote termux-adb..."
apt-get --assume-yes remove termux-adb 2>/dev/null || true

step "Limpando restos de apt (se existirem)..."
rm -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list"
rm -f "$PREFIX/etc/apt/trusted.gpg.d/nohajc.gpg"

step "Removendo ferramentas extras..."
rm -f "$PREFIX/bin/wireless-adb"
rm -f "$PREFIX/bin/termux-adb-doctor"
rm -f "$PREFIX/bin/termux-adb-update"
rm -f "$PREFIX/bin/adbotg"
rm -f "$PREFIX/bin/adbpair"
rm -f "$PREFIX/bin/adbw"
rm -f "$PREFIX/bin/adblocalhost"
rm -f "$PREFIX/bin/adbs"
rm -f "$PREFIX/bin/adbmenu"

step "Removendo front-ends unificados e watcher..."
rm -f "$HOME/.local/bin/adb"
rm -f "$HOME/.local/bin/fastboot"
rm -f "$HOME/.local/bin/adb-otg-watcher"
rm -f "$PREFIX/bin/adb.sh"
rm -f "$PREFIX/bin/fastboot.sh"

step "Limpando config dos shell RCs..."
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  sed -i '/ANDROID_USER_HOME=.*\.termux-adb/d' "$RC"
  sed -i '/ANDROID_SDK_HOME=.*\.termux-adb/d' "$RC"
done

step "Removendo dados isolados..."
rm -rf "$HOME/.termux-adb"

echo
if command -v termux-adb >/dev/null 2>&1 && [ ! -f "$HOME/.local/bin/adb" ]; then
  echo -e "${RED}[!]${NC} termux-adb ainda está no PATH — a remoção pode ter falhado parcialmente"
else
  info "termux-adb e ferramentas associadas removidos"
fi
echo