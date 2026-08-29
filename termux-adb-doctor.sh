#!/data/data/com.termux/files/usr/bin/bash
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ISSUES=$((ISSUES + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }

ISSUES=0

echo
echo "termux-adb doctor v4.0.0"
echo "========================"
echo

# 1. Binários
echo "Binários:"
if command -v termux-adb >/dev/null 2>&1; then
  VER="$(timeout 3 termux-adb version 2>/dev/null | head -1 || echo '?')"
  ok "termux-adb: $VER"
else
  fail "termux-adb não encontrado no PATH"
fi

if command -v termux-fastboot >/dev/null 2>&1; then
  VER="$(timeout 3 termux-fastboot --version 2>/dev/null | head -1 || echo '?')"
  ok "termux-fastboot: $VER"
else
  fail "termux-fastboot não encontrado no PATH"
fi
echo

# 2. Termux:API
echo "Termux:API:"
if command -v termux-usb >/dev/null 2>&1; then
  ok "termux-usb presente"
else
  fail "termux-usb não encontrado — instale termux-api (pkg install termux-api)"
fi

if timeout 3 termux-usb -l >/dev/null 2>&1; then
  ok "app Termux:API funcional"
else
  warn "termux-usb -l falhou — o app Termux:API pode não estar instalado (F-Droid)"
fi
echo

# 3. Pacote dpkg
echo "Pacote:"
if dpkg -s termux-adb >/dev/null 2>&1; then
  PKG_VER="$(dpkg -s termux-adb 2>/dev/null | grep '^Version:' | cut -d' ' -f2)"
  ok "termux-adb instalado via dpkg ($PKG_VER)"
else
  fail "pacote termux-adb não instalado"
fi

if wget -q --spider --timeout=5 "https://api.github.com/repos/rianprei/termux-adb/releases/latest" 2>/dev/null; then
  ok "GitHub Releases acessível"
else
  warn "GitHub Releases inacessível (sem internet ou API rate limit)"
fi
echo

# 4. Configuração
echo "Configuração:"
if [ -n "$ANDROID_USER_HOME" ]; then
  ok "ANDROID_USER_HOME=$ANDROID_USER_HOME"
elif [ -n "$ANDROID_SDK_HOME" ]; then
  warn "ANDROID_SDK_HOME definido (descontinuado) — rode install.sh para migrar para ANDROID_USER_HOME"
else
  warn "ANDROID_USER_HOME não definido — os dados do adb vão para \$HOME (rode install.sh para isolar)"
fi

if [ -d "$HOME/.termux-adb" ]; then
  ok "diretório ~/.termux-adb existe"
else
  warn "~/.termux-adb não existe (será criado no primeiro uso do adb)"
fi
echo

# 5. Front-ends unificados
echo "Front-ends (adb unificado):"
if [ -x "$HOME/.local/bin/adb" ]; then
  ok "front-end adb ok"
else
  warn "front-end adb ausente (rode install.sh)"
fi

if [ -x "$HOME/.local/bin/fastboot" ]; then
  ok "front-end fastboot ok"
else
  warn "front-end fastboot ausente (rode install.sh)"
fi

if [ -e "$HOME/.local/bin/adb-otg-watcher" ]; then
  ok "front-end adb-otg-watcher ok"
else
  warn "adb-otg-watcher ausente (rode install.sh)"
fi
echo

# 6. Ferramentas extras
echo "Ferramentas extras:"
for TOOL in wireless-adb termux-adb-update adbs adbmenu adbpair adbotg adbw adblocalhost; do
  if command -v "$TOOL" >/dev/null 2>&1; then
    ok "$TOOL instalado"
  else
    warn "$TOOL não instalado (rode install.sh para adicionar)"
  fi
done
echo

# Resultado
echo "========================"
if [ "$ISSUES" -eq 0 ]; then
  echo -e "${GREEN}Tudo OK — nenhum problema encontrado; o ambiente está pronto para uso.${NC}"
else
  echo -e "${RED}$ISSUES problema(s) encontrado(s) — rode install.sh para corrigir.${NC}"
fi
echo