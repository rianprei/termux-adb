#!/data/data/com.termux/files/usr/bin/bash
#
# adb-otg-watcher — mantém o cache OTG atualizado em segundo plano.
# O front-end `adb` lê apenas o cache (latência ~1ms). Atualiza a cada 4s.
# Uso: adb-otg-watcher [CACHE_FILE] [LOCK_FILE]

set -uo pipefail

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
USB="$PREFIX/bin/termux-usb"
CACHE="${1:-$HOME/.termux-adb/otg.cache}"
LOCK="${2:-$HOME/.termux-adb/otg.lock}"

mkdir -p "$(dirname "$CACHE")"

# flock impede múltiplas instâncias (single-instance no kernel).
exec 9>"$LOCK"
flock -n 9 || exit 0

while :; do
  if [ -x "$USB" ]; then
    out="$(timeout 3 "$USB" -l 2>/dev/null)"
    rc=$?
    if [ $rc -eq 0 ] && [ -n "$out" ] && [ "$out" != "[]" ] && [ "$out" != "null" ]; then
      printf '1' > "$CACHE" 2>/dev/null || true
    else
      printf '0' > "$CACHE" 2>/dev/null || true
    fi
  else
    printf '0' > "$CACHE" 2>/dev/null || true
  fi
  sleep 4
done