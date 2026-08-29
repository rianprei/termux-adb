#!/data/data/com.termux/files/usr/bin/bash
#
# adbw — conexão wireless interativa (Android 11+)
# Inclui pareamento com código e conexão subsequente.
# Porta de pareamento ≠ porta de conexão (consulte a tela de depuração wireless).

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'

info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
step() { echo -e "${BLUE}[>]${NC} $1"; }

command -v adb >/dev/null 2>&1 || fail "adb ausente — instale: pkg install android-tools"

validate_addr() {
  echo "$1" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}$' || fail "Formato inválido: '$1'. Use IP:PORTA (ex: 192.168.1.100:37123)"
}

echo
info "ADB Wireless (Android 11+, sem cabo/OTG, sem root)"
echo

LOCAL_IP="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[0-9.]+' || true)"
if [ -n "$LOCAL_IP" ]; then
  info "Seu IP local: $LOCAL_IP"
fi

echo -e "${BLUE}No aparelho alvo:${NC} Ajustes > Opções do desenvolvedor > Depuração wireless"
echo

read -rp "Já pareou este aparelho antes? [s/N] " PAIRED

if [ "$PAIRED" != "s" ] && [ "$PAIRED" != "S" ]; then
  echo
  step "Pareamento necessário"
  read -rp "IP:porta de pareamento (tela 'Parear com código'): " PAIR_ADDR
  validate_addr "$PAIR_ADDR"
  read -rp "Código de pareamento (6 dígitos): " PAIR_CODE
  [ -z "$PAIR_CODE" ] && fail "O código não pode ser vazio"
  info "Pareando..."
  timeout 15 adb pair "$PAIR_ADDR" "$PAIR_CODE" || fail "Pareamento falhou (timeout de 15s ou credenciais incorretas)"
  info "Pareamento concluído"
fi

echo
read -rp "IP:porta de conexão (porta de conexão, na tela principal de depuração wireless): " CONNECT_ADDR
validate_addr "$CONNECT_ADDR"

step "Conectando..."
timeout 15 adb connect "$CONNECT_ADDR" || fail "Conexão falhou (timeout de 15s). Verifique IP/porta e se a depuração wireless está ativa."

echo
info "Conectado. Dispositivos:"
adb devices
echo
echo "Observação: se o dispositivo ficar offline, execute 'adb kill-server' e reconecte."
echo "            A porta de conexão muda a cada reinicialização; o pareamento é único."