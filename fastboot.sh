#!/data/data/com.termux/files/usr/bin/bash
#
# fastboot — front-end unificado do termux-fastboot
# =================================================
# Sem root, sem bootloader. Encaminha para o termux-fastboot,
# que é a implementação compatível com OTG (termux-usb) no Termux.

set -uo pipefail

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
TERMUX_FASTBOOT="$PREFIX/bin/termux-fastboot"

case "${1:-}" in
  -h|--help|version) exec "$TERMUX_FASTBOOT" "$@" ;;
esac

exec "$TERMUX_FASTBOOT" "$@"