#!/data/data/com.termux/files/usr/bin/bash
#
# adb — Termux ADB Unificado v4.0.0
# ===============================
# Consolida as implementações de ADB do Termux em um único comando.
#
# Roteamento automático (sem root, sem bootloader):
#   ▪ OTG USB (dispositivo→dispositivo)  → termux-adb  (patch nohajc via termux-usb)
#   ▪ Wireless / localhost               → adb nativo  (android-tools, mais rápido)
#
# Detecção OTG via watcher em background → decisão em ~1ms, sem latência.
# O watcher é iniciado sob demanda e mantido vivo; nunca bloqueia.

set -uo pipefail

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
NATIVE_ADB="$PREFIX/bin/adb"
TERMUX_ADB="$PREFIX/bin/termux-adb"
TERMUX_USB="$PREFIX/bin/termux-usb"
ADB_DIR="$HOME/.termux-adb"
CACHE="$ADB_DIR/otg.cache"
WATCHER="$HOME/.local/bin/adb-otg-watcher"
WATCHER_PID="$ADB_DIR/otg-watcher.pid"

# Garante watcher vivo (instância única via flock, barato).
ensure_watcher() {
  [ -x "$WATCHER" ] || return 0
  if [ -f "$WATCHER_PID" ]; then
    local pid
    pid="$(cat "$WATCHER_PID" 2>/dev/null || true)"
    if [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null; then
      return 0
    fi
  fi
  "$WATCHER" "$CACHE" >/dev/null 2>&1 &
  printf '%s' "$!" > "$WATCHER_PID" 2>/dev/null || true
}

# Consulta o cache OTG sem bloquear (máx. 1 stat + 1 cat).
has_otg() {
  if [ -x "$TERMUX_USB" ] && [ -f "$CACHE" ]; then
    [ "$(cat "$CACHE" 2>/dev/null || printf '0')" = "1" ] && return 0 || return 1
  fi
  return 1
}

# Comandos puramente de rede/wireless → backend nativo sempre (mais rápido).
WIRELESS_OPS="pair connect disconnect tcpip mdns reconnect"

case "${1:-}" in
  -h|--help|"")
    echo "adb — Termux ADB Unificado v4.0.0"
    echo "  Backend automático: OTG via termux-usb | wireless via nativo"
    echo "  Sem latência: decisão via cache do watcher"
    echo "Ferramentas: adbpair, adbotg, adbs, adbw, adblocalhost, adbmenu"
    echo
    exit 0
    ;;
  version)
    ensure_watcher
    exec "$NATIVE_ADB" "$@"
    ;;
esac

if [[ " $WIRELESS_OPS " == *" ${1:-} "* ]]; then
  ensure_watcher
  exec "$NATIVE_ADB" "$@"
fi

ensure_watcher

if has_otg; then
  exec "$TERMUX_ADB" "$@"
fi

exec "$NATIVE_ADB" "$@"