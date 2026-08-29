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

VERSION="4.0.0"
PKG_VERSION="0.2.3"
RELEASE_URL="https://github.com/rianprei/termux-adb/releases/download/v${VERSION}"
RAW_URL="https://raw.githubusercontent.com/rianprei/termux-adb/main"
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

declare -A DEB_SHA256
DEB_SHA256[aarch64]="3f571ada3ea25671ab8a6d227c5f12f7e0412d8b62bf60e7948ae99a4c38c518"
DEB_SHA256[arm]="faf1ec047fa69dbafc9550574bdf4c91bc7c12c5372684d6c5d9cbe384e861a0"

# Scripts instalados no PATH (prefixo .sh removido)
EXTRA_SCRIPTS="wireless-adb termux-adb-doctor termux-adb-update adbotg adbpair adbw adblocalhost adbs adbmenu"
# Scripts instalados em $HOME/.local/bin (front-ends do adb unificado)
LOCALBIN_SCRIPTS="adb fastboot adb-otg-watcher"

echo
info "Termux ADB Unificado — instalador v${VERSION}"
echo

# 1. Verificação de arquitetura
step "Verificando arquitetura..."
ARCH="$(uname -m)"
case "$ARCH" in
  aarch64) DEB_ARCH="aarch64" ;;
  armv7l|armv8l|arm) DEB_ARCH="arm" ;;
  *)
    fail "Arquitetura '$ARCH' não suportada. Suportadas: aarch64, arm (armv7l/armv8l)"
    ;;
esac
info "Arquitetura: $ARCH → pacote $DEB_ARCH"

# 2. Dependências base
step "Instalando dependências base..."
apt-get update -qq
apt-get --assume-yes install wget > /dev/null

# 3. termux-api
step "Verificando termux-api..."
if ! command -v termux-usb >/dev/null 2>&1; then
  warn "termux-usb não encontrado. Instalando termux-api..."
  apt-get --assume-yes install termux-api > /dev/null
  info "termux-api instalado. Instale também o app Termux:API (F-Droid) se ainda não instalou."
else
  info "termux-api presente"
fi

# 4. Baixar e instalar o pacote .deb (distribuição própria, sem repo externo)
DEB_FILE="termux-adb_${PKG_VERSION}_${DEB_ARCH}.deb"
DEB_TMP="$(mktemp)"
EXPECTED_SHA="${DEB_SHA256[$DEB_ARCH]}"

step "Baixando $DEB_FILE..."
if ! wget -qO "$DEB_TMP" --timeout=30 "${RELEASE_URL}/${DEB_FILE}" 2>/dev/null; then
  rm -f "$DEB_TMP"
  fail "Falha ao baixar $DEB_FILE. Verifique a conexão ou abra uma issue em github.com/rianprei/termux-adb"
fi

step "Verificando integridade (SHA256)..."
ACTUAL_SHA="$(sha256sum "$DEB_TMP" | cut -d' ' -f1)"
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  rm -f "$DEB_TMP"
  fail "SHA256 não confere! Esperado: $EXPECTED_SHA / Recebido: $ACTUAL_SHA. Possível corrupção. Abra uma issue em github.com/rianprei/termux-adb"
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

# 6. Ferramentas extras no PATH ($PREFIX/bin)
step "Instalando ferramentas extras..."
for SCRIPT in $EXTRA_SCRIPTS; do
  if wget -qO "$PREFIX/bin/$SCRIPT" --timeout=10 "${RAW_URL}/${SCRIPT}.sh" 2>/dev/null; then
    chmod +x "$PREFIX/bin/$SCRIPT"
    info "$SCRIPT instalado"
  else
    warn "Falha ao baixar $SCRIPT (não crítico)"
  fi
done

# 7. Front-ends do adb unificado em $HOME/.local/bin
#    (ficam antes de $PREFIX/bin no PATH e roteiam OTG/wireless)
step "Instalando front-ends unificados..."
mkdir -p "$HOME/.local/bin"
for SCRIPT in $LOCALBIN_SCRIPTS; do
  if wget -qO "$HOME/.local/bin/$SCRIPT" --timeout=10 "${RAW_URL}/${SCRIPT}.sh" 2>/dev/null; then
    chmod +x "$HOME/.local/bin/$SCRIPT"
    info "$SCRIPT instalado"
  else
    warn "Falha ao baixar $SCRIPT (não crítico)"
  fi
done

# Garante $HOME/.local/bin no PATH
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) export PATH="$HOME/.local/bin:$PATH"
     for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
       [ -f "$RC" ] || continue
       grep -q '\.local/bin' "$RC" 2>/dev/null && continue
       echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$RC"
     done
     ;;
esac

# 8. Health-check
step "Verificando instalação..."
echo
if ADB_VER="$(termux-adb version 2>/dev/null | head -1)"; then
  info "termux-adb OK: $ADB_VER"
else
  warn "termux-adb instalado, mas 'termux-adb version' falhou. Execute 'termux-adb-doctor' para diagnosticar."
fi

if FB_VER="$(termux-fastboot --version 2>/dev/null | head -1)"; then
  info "termux-fastboot OK: $FB_VER"
else
  warn "termux-fastboot não respondeu (pode não estar disponível nesta versão)"
fi

echo
info "Instalação concluída!"
info "Comandos: adb, fastboot, adbw, adbmenu, adbs, adbpair, adbotg, adblocalhost, wireless-adb, termux-adb-doctor, termux-adb-update"
info "Distribuição própria — binários hospedados no nosso repositório."
echo