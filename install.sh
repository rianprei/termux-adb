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

VERSION="3.0.0"
PKG_VERSION="0.2.3"
RELEASE_URL="https://github.com/rianprei/termux-adb/releases/download/v${VERSION}"
RAW_URL="https://raw.githubusercontent.com/rianprei/termux-adb/main"

declare -A DEB_SHA256
DEB_SHA256[aarch64]="3f571ada3ea25671ab8a6d227c5f12f7e0412d8b62bf60e7948ae99a4c38c518"
DEB_SHA256[arm]="faf1ec047fa69dbafc9550574bdf4c91bc7c12c5372684d6c5d9cbe384e861a0"

echo
info "termux-adb installer v${VERSION} (self-contained)"
echo

# 1. Arch check
step "Verificando arquitetura..."
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) DEB_ARCH="aarch64" ;;
  armv7l|armv8l|arm) DEB_ARCH="arm" ;;
  *)
    fail "Arquitetura '$ARCH' nao suportada. Suportadas: aarch64, arm (armv7l/armv8l)"
    ;;
esac
info "Arquitetura: $ARCH → pacote $DEB_ARCH"

# 2. Dependencias base
step "Instalando dependencias base..."
apt-get update -qq
apt-get --assume-yes install wget > /dev/null

# 3. termux-api
step "Verificando termux-api..."
if ! command -v termux-usb >/dev/null 2>&1; then
  warn "termux-usb nao encontrado. Instalando termux-api..."
  apt-get --assume-yes install termux-api > /dev/null
  info "termux-api instalado. Instale tambem o app Termux:API (F-Droid) se ainda nao instalou."
else
  info "termux-api presente"
fi

# 4. Baixar e instalar o .deb direto do nosso repo (sem depender de repo externo)
DEB_FILE="termux-adb_${PKG_VERSION}_${DEB_ARCH}.deb"
DEB_TMP="$(mktemp)"
EXPECTED_SHA="${DEB_SHA256[$DEB_ARCH]}"

step "Baixando $DEB_FILE..."
if ! wget -qO "$DEB_TMP" --timeout=30 "${RELEASE_URL}/${DEB_FILE}" 2>/dev/null; then
  rm -f "$DEB_TMP"
  fail "Falha ao baixar $DEB_FILE. Verifique conexao ou abra issue em github.com/rianprei/termux-adb"
fi

step "Verificando integridade (SHA256)..."
ACTUAL_SHA="$(sha256sum "$DEB_TMP" | cut -d' ' -f1)"
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  rm -f "$DEB_TMP"
  fail "SHA256 nao confere! Esperado: $EXPECTED_SHA / Recebido: $ACTUAL_SHA. Possivel corrupcao. Abra issue em github.com/rianprei/termux-adb"
fi
info "Integridade verificada"

step "Instalando termux-adb..."
dpkg -i "$DEB_TMP" 2>/dev/null || apt-get --assume-yes -f install > /dev/null
rm -f "$DEB_TMP"

# 5. Isolar dados do adb
step "Isolando dados do adb..."
mkdir -p "$HOME/.termux-adb"
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  grep -q 'ANDROID_USER_HOME=.*\.termux-adb' "$RC" 2>/dev/null && continue
  sed -i '/ANDROID_SDK_HOME=.*\.termux-adb/d' "$RC"
  echo 'export ANDROID_USER_HOME="$HOME/.termux-adb"' >> "$RC"
  echo 'export ANDROID_SDK_HOME="$HOME/.termux-adb"' >> "$RC"
done
export ANDROID_USER_HOME="$HOME/.termux-adb"
export ANDROID_SDK_HOME="$HOME/.termux-adb"
info "Dados do adb isolados em ~/.termux-adb"

# 6. Ferramentas extras
step "Instalando ferramentas extras..."
wget -qO "$PREFIX/bin/wireless-adb" --timeout=10 "${RAW_URL}/wireless-adb.sh" 2>/dev/null && chmod +x "$PREFIX/bin/wireless-adb" && info "wireless-adb instalado" || warn "Falha ao baixar wireless-adb (nao-critico)"
wget -qO "$PREFIX/bin/termux-adb-doctor" --timeout=10 "${RAW_URL}/termux-adb-doctor.sh" 2>/dev/null && chmod +x "$PREFIX/bin/termux-adb-doctor" && info "termux-adb-doctor instalado" || warn "Falha ao baixar termux-adb-doctor (nao-critico)"

# 7. Health-check
step "Verificando instalacao..."
echo
if ADB_VER="$(termux-adb version 2>/dev/null | head -1)"; then
  info "termux-adb OK: $ADB_VER"
else
  warn "termux-adb instalado mas 'termux-adb version' falhou. Rode 'termux-adb-doctor' para diagnosticar."
fi

if FB_VER="$(termux-fastboot --version 2>/dev/null | head -1)"; then
  info "termux-fastboot OK: $FB_VER"
else
  warn "termux-fastboot nao respondeu (pode nao estar disponivel nesta versao)"
fi

echo
info "Instalacao completa!"
info "Comandos: termux-adb, termux-fastboot, wireless-adb, termux-adb-doctor"
info "Nenhuma dependencia externa — binarios hospedados no nosso repo."
echo
