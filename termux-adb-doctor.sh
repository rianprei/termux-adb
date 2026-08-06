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
echo "termux-adb doctor v3.0.0"
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

# 3. Repo apt
echo "Repositorio:"
if [ -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list" ]; then
  ok "sources.list presente"
else
  fail "termux-adb.list nao encontrado em sources.list.d/"
fi

if [ -f "$PREFIX/etc/apt/trusted.gpg.d/nohajc.gpg" ]; then
  ok "GPG key presente"
else
  fail "nohajc.gpg nao encontrada em trusted.gpg.d/"
fi

if wget -q --spider --timeout=5 "https://nohajc.github.io/dists/termux/Release" 2>/dev/null; then
  ok "repo apt online"
else
  fail "repo apt offline ou inacessivel (nohajc.github.io)"
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

# 5. Ferramentas extras
echo "Extras:"
if command -v wireless-adb >/dev/null 2>&1; then
  ok "wireless-adb instalado"
else
  warn "wireless-adb nao instalado (rode install.sh para adicionar)"
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
