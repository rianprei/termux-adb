#!/data/data/com.termux/files/usr/bin/bash
#
# adblocalhost — conecta ao próprio aparelho (127.0.0.1) via depuração wireless.
# Procedimento baseado nos guias de pareamento localhost (local ADB).

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }

command -v adb >/dev/null 2>&1 || fail "adb ausente"

echo
info "ADB no próprio aparelho (127.0.0.1) — Android 11+"
echo
echo -e "${BLUE}Preparação:${NC} Ative 'Depuração wireless' em Opções do desenvolvedor."
echo -e "${BLUE}Recomendação:${NC} use split-screen (o diálogo de pareamento fecha ao sair dele)."
echo
read -rp "Já pareou 127.0.0.1 antes? [s/N] " PAIRED

if [ "$PAIRED" != "s" ] && [ "$PAIRED" != "S" ]; then
  read -rp "Porta de PAREAMENTO (menu 'Parear com código'): " PP
  [ -n "$PP" ] && [ "$PP" -eq "$PP" ] 2>/dev/null || fail "Porta inválida"
  read -rp "Código de 6 dígitos: " CODE
  [ -z "$CODE" ] && fail "Código vazio"
  info "Pareando..."
  timeout 15 adb pair "127.0.0.1:$PP" "$CODE" || fail "Pareamento falhou"
fi

read -rp "Porta de CONEXÃO (menu 'IP address & Port' — diferente da de pareamento): " CP
[ -n "$CP" ] && [ "$CP" -eq "$CP" ] 2>/dev/null || fail "Porta inválida"

info "Conectando..."
timeout 15 adb connect "127.0.0.1:$CP" || fail "Conexão falhou"
adb devices

echo
echo "Recursos disponíveis após a conexão:"
echo "  adb shell                  — shell Android"
echo "  ADBash.sh                  — shell Bash na sessão ADB"
echo "  scrcpy                     — espelhamento de tela"
echo "  adb pull/push/install      — arquivos e aplicativos"