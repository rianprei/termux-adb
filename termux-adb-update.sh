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

REPO="rianprei/termux-adb"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"
RAW_URL="https://raw.githubusercontent.com/${REPO}/main"

echo
info "termux-adb-update — verificando atualizacoes"
echo

step "Consultando ultima release..."
LATEST="$(wget -qO- --timeout=10 "$API_URL" 2>/dev/null)" || fail "Falha ao consultar GitHub API. Verifique conexao."

LATEST_TAG="$(echo "$LATEST" | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
[ -z "$LATEST_TAG" ] && fail "Nao foi possivel obter tag da ultima release"

INSTALLED_VER=""
if command -v termux-adb >/dev/null 2>&1; then
  INSTALLED_VER="$(termux-adb version 2>/dev/null | head -1 || echo '?')"
fi

info "Release mais recente: $LATEST_TAG"
info "Versao instalada: ${INSTALLED_VER:-nao encontrada}"
echo

step "Atualizando scripts..."
for SCRIPT in wireless-adb.sh termux-adb-doctor.sh termux-adb-update.sh; do
  TARGET="${SCRIPT%.sh}"
  wget -qO "$PREFIX/bin/$TARGET" --timeout=10 "${RAW_URL}/${SCRIPT}" 2>/dev/null && chmod +x "$PREFIX/bin/$TARGET" && info "$TARGET atualizado" || warn "Falha ao atualizar $TARGET"
done

step "Atualizando install.sh para nova versao..."
INSTALL_TMP="$(mktemp)"
if wget -qO "$INSTALL_TMP" --timeout=10 "${RAW_URL}/install.sh" 2>/dev/null; then
  NEW_PKG_VER="$(grep '^PKG_VERSION=' "$INSTALL_TMP" | cut -d'"' -f2)"
  CUR_PKG_VER="$(dpkg -s termux-adb 2>/dev/null | grep '^Version:' | cut -d' ' -f2)"

  if [ -n "$NEW_PKG_VER" ] && [ -n "$CUR_PKG_VER" ] && [ "$NEW_PKG_VER" != "$CUR_PKG_VER" ]; then
    info "Nova versao do pacote disponivel: $CUR_PKG_VER -> $NEW_PKG_VER"
    step "Reinstalando com novo install.sh..."
    bash "$INSTALL_TMP"
  else
    info "Pacote termux-adb ja esta na versao mais recente ($CUR_PKG_VER)"
  fi
  rm -f "$INSTALL_TMP"
else
  rm -f "$INSTALL_TMP"
  warn "Falha ao baixar install.sh (scripts ja foram atualizados)"
fi

# Recriar symlinks
ln -sf "$PREFIX/bin/termux-adb" "$PREFIX/bin/adb" 2>/dev/null
ln -sf "$PREFIX/bin/termux-fastboot" "$PREFIX/bin/fastboot" 2>/dev/null

echo
info "Atualizacao concluida!"
echo
