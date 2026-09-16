#!/data/data/com.termux/files/usr/bin/bash
#
# adb-keys-backup — backup/restore das chaves RSA de host do adb (item 4 da §12.5)
#
# As chaves em ~/.termux-adb (ANDROID_USER_HOME do install.sh) são a identidade
# do host adb: perder = re-aceitar prompt RSA em todos os devices. Backup =
# tar czf com as chaves; restore recoloca no lugar com permissões corretas.
#
# Uso:
#   adb-keys-backup              # cria backup em ~/storage/downloads (ou $HOME)
#   adb-keys-backup <arquivo>    # restore a partir do arquivo
#
# Nota: adb keygen (rotação de chave) existe no platform-tools; o binário do
# Termux (nmeum) não inclui o keygen em todas as versões — backup é o caminho
# seguro que independe disso.

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

KEYS_DIR="${ANDROID_USER_HOME:-${ANDROID_SDK_HOME:-$HOME/.termux-adb}}"

mode_restore() {
  [ -f "$1" ] || fail "arquivo de backup não encontrado: $1"
  tar tzf "$1" >/dev/null 2>&1 || fail "arquivo inválido (não é tar.gz legível): $1"
  mkdir -p "$KEYS_DIR"
  tar xzf "$1" -C "$KEYS_DIR"
  chmod 700 "$KEYS_DIR"
  [ -f "$KEYS_DIR/adbkey" ] && chmod 600 "$KEYS_DIR/adbkey"
  [ -f "$KEYS_DIR/adbkey.pub" ] && chmod 644 "$KEYS_DIR/adbkey.pub"
  info "chaves restauradas em $KEYS_DIR"
  info "reinicie o server pra usar: adb kill-server && adb devices"
}

mode_backup() {
  [ -f "$KEYS_DIR/adbkey" ] || fail "sem chaves pra backup em $KEYS_DIR (rode 'adb devices' uma vez pra gerar)"

  OUT_DIR="$HOME/storage/downloads"
  [ -d "$OUT_DIR" ] || OUT_DIR="$HOME"
  OUT="$OUT_DIR/adbw-keys-$(date +%Y%m%d-%H%M%S).tar.gz"

  tar czf "$OUT" -C "$KEYS_DIR" adbkey adbkey.pub 2>/dev/null \
    || fail "falha ao criar $OUT (chaves adbkey/adbkey.pub ausentes?)"

  chmod 600 "$OUT"
  info "backup criado: $OUT (perm 600 — contém chave privada)"
  warn "guarde em local seguro; a adbkey é a identidade do seu host adb — quem tem ela conecta sem prompt nos devices autorizados"
  info "restore: adb-keys-backup '$(basename "$OUT")'"
}

case "${1:-}" in
  "")    mode_backup ;;
  -h|--help)
    sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
    ;;
  *)     mode_restore "$1" ;;
esac
