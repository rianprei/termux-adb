#!/data/data/com.termux/files/usr/bin/bash
set -e

command -v termux-adb >/dev/null 2>&1 || { echo "termux-adb nao instalado. Rode install.sh primeiro." >&2; exit 1; }

echo "Wireless ADB (Android 11+, sem cabo/OTG, sem root)"
echo
echo "No celular: Ajustes > Opcoes do desenvolvedor > Depuracao wireless"
echo
read -rp "Ja pareou este dispositivo antes? [s/N] " PAIRED

if [ "$PAIRED" != "s" ] && [ "$PAIRED" != "S" ]; then
  read -rp "IP:porta de pareamento (tela 'Parear com codigo'): " PAIR_ADDR
  read -rp "Codigo de pareamento (6 digitos): " PAIR_CODE
  termux-adb pair "$PAIR_ADDR" "$PAIR_CODE"
fi

read -rp "IP:porta de conexao (tela principal de depuracao wireless): " CONNECT_ADDR
termux-adb connect "$CONNECT_ADDR"
termux-adb devices
