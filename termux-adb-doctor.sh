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
for TOOL in wireless-adb termux-adb-update adbs adbmenu adbpair adbotg adbw adbw-root-porta adblocalhost; do
  if command -v "$TOOL" >/dev/null 2>&1; then
    ok "$TOOL instalado"
  else
    warn "$TOOL não instalado (rode install.sh para adicionar)"
  fi
done
echo

# 6.1 Phantom process killer (Android 12+ mata processos filhos do Termux,
#     incluindo o server adb) — fonte: context/termux-adb-research.md §4/§10.2
echo "Phantom process killer (Android 12+):"
if command -v settings >/dev/null 2>&1; then
  PHANTOM="$(settings get global settings_enable_monitor_phantom_procs 2>/dev/null || echo 'inacessivel')"
  case "$PHANTOM" in
    null|0)  ok "phantom killer desativado ($PHANTOM)" ;;
    1)       warn "phantom killer ATIVO — pode matar o server adb do Termux (signal 9)"; 
             warn "  mitigação: settings put global settings_enable_monitor_phantom_procs false (via sessão adb)" ;;
    *)       warn "não foi possível ler a setting (rode via sessão adb/termux-api): '$PHANTOM'" ;;
  esac
else
  warn "comando settings ausente — check do phantom killer pulado"
fi
echo

# 6.2 mDNS no binário android-tools — o build do Termux (nmeum) compila com
#     ANDROID_TOOLS_ADB_ENABLE_MDNS=OFF (§12.1 do research): ausência é ESPERADO, não erro
echo "mDNS do binário adb:"
if timeout 5 adb mdns services >/dev/null 2>&1; then
  ok "adb mdns disponível (binário compilado com mDNS)"
else
  warn "adb mdns indisponível — ESPERADO no Termux (android-tools compila sem mDNS, não é defeito)"
  warn "  descoberta de porta dinâmica: use nmap (item 5) ou porta fixa via adbw-root-porta (root)"
fi
echo

# 6.3 Chaves de host em ~/.termux-adb (identidade RSA do host adb)
echo "Chaves de host (~/.termux-adb):"
KEYS_DIR="${ANDROID_USER_HOME:-$HOME/.termux-adb}"
if [ -f "$KEYS_DIR/adbkey" ] && [ -f "$KEYS_DIR/adbkey.pub" ]; then
  ok "chaves RSA presentes ($KEYS_DIR/adbkey{,.pub})"
  warn "  backup recomendado: tar czf adbw-keys-backup.tar.gz -C '$KEYS_DIR' adbkey adbkey.pub"
else
  warn "chaves RSA ausentes em $KEYS_DIR (geradas no primeiro uso; sem elas cada conexão nova pede prompt)"
fi
echo

# 6.4 Módulo Magisk termuxadb_rootport (porta fixa 5555 no boot)
# Nota: /data/adb/modules/ é raiz-only (Termux não le direto, "ls" sem su
# falha silenciosamente = falso negativo). Checa direto pelo efeito real da
# prop, que é publica pra leitura (getprop nao exige root) — mais robusto,
# cobre qualquer metodo que fixou a porta, não só este módulo específico.
echo "Porta ADB fixa (módulo Magisk ou equivalente):"
RP="$(getprop persist.adb.tcp.port 2>/dev/null || true)"
if [ "$RP" = "5555" ]; then
  ok "porta fixa ativa (persist.adb.tcp.port=5555)"
else
  warn "porta não fixada ('${RP:-vazia}') — instale o módulo Magisk termux-adb-magisk-rootport (root) pra parar de descobrir porta TLS aleatória a cada boot"
fi
echo

# Resultado
echo "========================"
if [ "$ISSUES" -eq 0 ]; then
  echo -e "${GREEN}Tudo OK — nenhum problema encontrado; o ambiente está pronto para uso.${NC}"
else
  echo -e "${RED}$ISSUES problema(s) encontrado(s) — rode install.sh para corrigir.${NC}"
fi
echo