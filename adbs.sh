#!/data/data/com.termux/files/usr/bin/bash
#
# adbs — status geral do sistema ADB (diagnóstico rápido).
# Consolida wireless-adb-doctor + termux-adb-doctor em uma visão única.

set -uo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}

cat_tool() { timeout 3 "$1" version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+[^ ]*' | head -1; }

echo
echo -e "${BLUE}Termux ADB — Diagnóstico${NC}"
echo "================================="
echo

echo "Backends:"
for b in adb termux-adb; do
  if command -v "$b" >/dev/null 2>&1; then
    V="$(cat_tool "$b")"
    ok "$b: ${V:-(versão ok)}"
  else
    fail "$b: ausente"
  fi
done

# termux-fastboot é lento na enumeração USB — checa apenas presença
for b in fastboot termux-fastboot; do
  if command -v "$b" >/dev/null 2>&1; then
    ok "$b: presente"
  else
    fail "$b: ausente"
  fi
done
echo

echo "Termux:API / USB:"
if command -v termux-usb >/dev/null 2>&1; then
  CACHE="$HOME/.termux-adb/otg.cache"
  if [ -f "$CACHE" ]; then
    if [ "$(cat "$CACHE" 2>/dev/null)" = "1" ]; then
      ok "termux-usb: dispositivos OTG conectados"
    else
      warn "termux-usb disponível — nenhum dispositivo OTG conectado"
    fi
  else
    OUT="$(timeout 4 termux-usb -l 2>&1)"
    RC=$?
    if [ $RC -ne 0 ]; then
      fail "termux-usb falhou (código $RC) — instale o app Termux:API via F-Droid"
    elif [ "$OUT" = "[]" ]; then
      warn "termux-usb disponível — nenhum dispositivo OTG conectado"
    else
      ok "termux-usb: $(echo "$OUT" | tr -d '[]" ' | sed 's/,/, /g')"
    fi
  fi
else
  fail "termux-usb ausente (pkg install termux-api)"
fi
echo

echo "Ambiente:"
if [ -n "${ANDROID_USER_HOME:-}" ]; then
  ok "ANDROID_USER_HOME=$ANDROID_USER_HOME"
else
  warn "ANDROID_USER_HOME não definido"
fi
if command -v scrcpy >/dev/null 2>&1; then
  ok "scrcpy: $(timeout 3 scrcpy --version 2>/dev/null | head -1)"
else
  warn "scrcpy não instalado (pkg install scrcpy)"
fi
if [ -x "$HOME/.local/bin/ADBash.sh" ]; then
  ok "ADBash: presente"
else
  warn "ADBash ausente"
fi
echo

echo "Dispositivos (adb devices):"
timeout 5 adb devices 2>&1 || warn "adb devices demorou — execute 'adb kill-server' e tente novamente"
echo