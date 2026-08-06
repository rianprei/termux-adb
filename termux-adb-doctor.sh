#!/data/data/com.termux/files/usr/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; ISSUES=$((ISSUES + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; }

ISSUES=0

echo
echo "termux-adb doctor v3.1.0"
echo "========================"
echo

# 1. termux-adb
echo "Binarios:"
if command -v termux-adb >/dev/null 2>&1; then
  VER="$(termux-adb version 2>/dev/null | head -1 || echo '?')"
  ok "termux-adb: $VER"
else
  fail "termux-adb nao encontrado no PATH"
fi

if command -v termux-fastboot >/dev/null 2>&1; then
  VER="$(termux-fastboot --version 2>/dev/null | head -1 || echo '?')"
  ok "termux-fastboot: $VER"
else
  fail "termux-fastboot nao encontrado no PATH"
fi
echo

# 2. termux-api
echo "Termux:API:"
if command -v termux-usb >/dev/null 2>&1; then
  ok "termux-usb presente"
else
  fail "termux-usb nao encontrado — instale termux-api (pkg install termux-api)"
fi

if termux-usb -l >/dev/null 2>&1; then
  ok "app Termux:API funcional"
else
  warn "termux-usb -l falhou — app Termux:API pode nao estar instalado (F-Droid)"
fi
echo

# 3. Pacote dpkg
echo "Pacote:"
if dpkg -s termux-adb >/dev/null 2>&1; then
  PKG_VER="$(dpkg -s termux-adb 2>/dev/null | grep '^Version:' | cut -d' ' -f2)"
  ok "termux-adb instalado via dpkg ($PKG_VER)"
else
  fail "pacote termux-adb nao instalado"
fi

if wget -q --spider --timeout=5 "https://api.github.com/repos/rianprei/termux-adb/releases/latest" 2>/dev/null; then
  ok "GitHub Releases acessivel"
else
  warn "GitHub Releases inacessivel (sem internet ou API rate limit)"
fi
echo

# 4. Config
echo "Configuracao:"
if [ -n "$ANDROID_USER_HOME" ]; then
  ok "ANDROID_USER_HOME=$ANDROID_USER_HOME"
elif [ -n "$ANDROID_SDK_HOME" ]; then
  warn "ANDROID_SDK_HOME definido (deprecated) — rode install.sh para atualizar para ANDROID_USER_HOME"
else
  warn "ANDROID_USER_HOME nao definido — dados do adb vao para \$HOME (rode install.sh para isolar)"
fi

if [ -d "$HOME/.termux-adb" ]; then
  ok "diretorio ~/.termux-adb existe"
else
  warn "~/.termux-adb nao existe (sera criado no primeiro uso do adb)"
fi
echo

# 5. Ferramentas extras e symlinks
echo "Extras:"
for TOOL in wireless-adb termux-adb-update; do
  if command -v "$TOOL" >/dev/null 2>&1; then
    ok "$TOOL instalado"
  else
    warn "$TOOL nao instalado (rode install.sh para adicionar)"
  fi
done

echo
echo "Symlinks:"
if [ -L "$PREFIX/bin/adb" ] && [ "$(readlink "$PREFIX/bin/adb")" = "$PREFIX/bin/termux-adb" ]; then
  ok "adb -> termux-adb"
else
  warn "symlink adb nao encontrado (rode install.sh para criar)"
fi

if [ -L "$PREFIX/bin/fastboot" ] && [ "$(readlink "$PREFIX/bin/fastboot")" = "$PREFIX/bin/termux-fastboot" ]; then
  ok "fastboot -> termux-fastboot"
else
  warn "symlink fastboot nao encontrado (rode install.sh para criar)"
fi
echo

# Resultado
echo "========================"
if [ "$ISSUES" -eq 0 ]; then
  echo -e "${GREEN}Tudo OK — nenhum problema encontrado.${NC}"
else
  echo -e "${RED}$ISSUES problema(s) encontrado(s).${NC}"
fi
echo
