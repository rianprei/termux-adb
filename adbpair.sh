#!/data/data/com.termux/files/usr/bin/bash
#
# adbpair — pareamento wireless rápido (Android 11+)
# Uso: adbpair IP:PORTA_PAREAMENTO CODIGO [IP:PORTA_CONEXAO]
# Se a porta de conexão não for informada, apenas o pareamento é executado.

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

usage() {
  echo "Uso: adbpair IP:PORTA_PAREAMENTO CODIGO [IP:PORTA_CONEXAO]" >&2
  exit 1
}

[ $# -lt 2 ] || [ $# -gt 3 ] && usage

PAIR_ADDR="$1"; CODE="$2"; CONNECT_ADDR="${3:-}"

echo -e "${GREEN}[*]${NC} Pareando com $PAIR_ADDR ..."
adb pair "$PAIR_ADDR" "$CODE"
[ $? -eq 0 ] || { echo -e "${RED}[!]${NC} O pareamento falhou."; exit 1; }

if [ -n "$CONNECT_ADDR" ]; then
  echo -e "${GREEN}[*]${NC} Conectando em $CONNECT_ADDR ..."
  adb connect "$CONNECT_ADDR"
fi

echo -e "${GREEN}[*]${NC} Dispositivos:"
adb devices