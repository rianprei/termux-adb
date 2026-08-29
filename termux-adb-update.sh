#!/data/data/com.termux/files/usr/bin/bash
set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()  { echo -e "${GREEN}[*]${NC} $1"; }
warn()  { echo -e "${YELLOW}[!]${NC} $1" >&2; }
fail()  { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
step()  { echo -e "${BLUE}[>]${NC} $1"; }

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
REPO="rianprei/termux-adb"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main"

# Scripts extras instalados em $PREFIX/bin
EXTRA_SCRIPTS="wireless-adb.sh termux-adb-doctor.sh termux-adb-update.sh adbotg.sh adbpair.sh adbw.sh adblocalhost.sh adbs.sh adbmenu.sh"
# Front-ends unificados instalados em $HOME/.local/bin
LOCALBIN_SCRIPTS="adb.sh fastboot.sh adb-otg-watcher.sh"

echo
info "termux-adb-update v4.0.0 — verificando atualizações"
echo

step "Consultando a última release..."
LATEST="$(wget -qO- --timeout=10 "$API_URL" 2>/dev/null)" || fail "Falha ao consultar GitHub API. Verifique a conexão."

LATEST_TAG="$(echo "$LATEST" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
[ -z "$LATEST_TAG" ] && fail "Não foi possível obter a tag da última release"

INSTALLED_VER=""
if command -v termux-adb >/dev/null 2>&1; then
  INSTALLED_VER="$(timeout 3 termux-adb version 2>/dev/null | head -1 || echo '?')"
fi

info "Release mais recente: $LATEST_TAG"
info "Versão instalada: ${INSTALLED_VER:-não encontrada}"
echo

step "Atualizando scripts no PATH (\$PREFIX/bin)..."
for SCRIPT in $EXTRA_SCRIPTS; do
  TARGET="${SCRIPT%.sh}"
  wget -qO "$PREFIX/bin/$TARGET" --timeout=10 "${RAW_URL}/${SCRIPT}" 2>/dev/null && chmod +x "$PREFIX/bin/$TARGET" && info "$TARGET atualizado" || warn "Falha ao atualizar $TARGET"
done

step "Atualizando front-ends unificados (\$HOME/.local/bin)..."
mkdir -p "$HOME/.local/bin"
for SCRIPT in $LOCALBIN_SCRIPTS; do
  TARGET="${SCRIPT%.sh}"
  wget -qO "$HOME/.local/bin/$TARGET" --timeout=10 "${RAW_URL}/${SCRIPT}" 2>/dev/null && chmod +x "$HOME/.local/bin/$TARGET" && info "$TARGET atualizado" || warn "Falha ao atualizar $TARGET"
done

step "Atualizando install.sh para a nova versão..."
INSTALL_TMP="$(mktemp)"
if wget -qO "$INSTALL_TMP" --timeout=10 "${RAW_URL}/install.sh" 2>/dev/null; then
  NEW_PKG_VER="$(grep '^PKG_VERSION=' "$INSTALL_TMP" | cut -d'"' -f2)"
  CUR_PKG_VER="$(dpkg -s termux-adb 2>/dev/null | grep '^Version:' | cut -d' ' -f2)"

  if [ -n "$NEW_PKG_VER" ] && [ -n "$CUR_PKG_VER" ] && [ "$NEW_PKG_VER" != "$CUR_PKG_VER" ]; then
    info "Nova versão do pacote disponível: $CUR_PKG_VER -> $NEW_PKG_VER"
    step "Reinstalando com o novo install.sh..."
    bash "$INSTALL_TMP"
  else
    info "Pacote termux-adb já está na versão mais recente (${CUR_PKG_VER:-desconhecida})"
  fi
  rm -f "$INSTALL_TMP"
else
  rm -f "$INSTALL_TMP"
  warn "Falha ao baixar install.sh (scripts já foram atualizados)"
fi

echo
info "Atualização concluída!"
echo