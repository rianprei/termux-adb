#!/data/data/com.termux/files/usr/bin/bash
#
# adbotg — lista e verifica dispositivos USB OTG via termux-usb (sem root)
# Uso: adbotg

set -uo pipefail

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
USB="$PREFIX/bin/termux-usb"

if ! [ -x "$USB" ]; then
  echo "[ERRO] termux-usb ausente. Instale: pkg install termux-api" >&2
  exit 1
fi

echo "[*] Dispositivos USB detectados (termux-usb -l):"
"$USB" -l 2>&1

echo
echo "[*] Para conceder permissão em um dispositivo:"
echo "    termux-usb -r /dev/bus/usb/001/002"
echo "[*] Para usá-lo com o adb:"
echo "    adb devices"