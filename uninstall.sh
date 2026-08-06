#!/data/data/com.termux/files/usr/bin/bash
set -e

apt-get --assume-yes remove termux-adb
rm -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list"
rm -f "$PREFIX/etc/apt/trusted.gpg.d/nohajc.gpg"
apt update

for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  sed -i '/ANDROID_SDK_HOME=.*\.termux-adb/d' "$RC"
done
rm -rf "$HOME/.termux-adb"

echo "termux-adb removido, repo desativado e config limpa."
