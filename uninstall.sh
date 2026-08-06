#!/data/data/com.termux/files/usr/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
step()  { echo -e "${BLUE}[>]${NC} $1"; }

echo
info "termux-adb uninstaller v3.0.0"
echo

step "Removendo pacote termux-adb..."
apt-get --assume-yes remove termux-adb 2>/dev/null || true

step "Removendo repo apt e GPG key..."
rm -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list"
rm -f "$PREFIX/etc/apt/trusted.gpg.d/nohajc.gpg"
apt-get update -qq

step "Removendo ferramentas extras..."
rm -f "$PREFIX/bin/wireless-adb"
rm -f "$PREFIX/bin/termux-adb-doctor"

step "Limpando config dos shell RCs..."
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  sed -i '/ANDROID_USER_HOME=.*\.termux-adb/d' "$RC"
  sed -i '/ANDROID_SDK_HOME=.*\.termux-adb/d' "$RC"
done

step "Removendo dados isolados..."
rm -rf "$HOME/.termux-adb"

echo
if command -v termux-adb >/dev/null 2>&1; then
  echo -e "${RED}[!]${NC} termux-adb ainda no PATH — remocao pode ter falhado parcialmente"
else
  info "termux-adb removido completamente"
fi
echo
