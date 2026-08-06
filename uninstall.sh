#!/data/data/com.termux/files/usr/bin/bash
set -e

apt-get --assume-yes remove termux-adb
rm -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list"
rm -f "$PREFIX/etc/apt/trusted.gpg.d/nohajc.gpg"
apt update

echo "termux-adb removido e repo desativado."
