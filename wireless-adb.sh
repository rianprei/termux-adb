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

command -v termux-adb >/dev/null 2>&1 || fail "termux-adb nao instalado. Rode install.sh primeiro."

validate_addr() {
  echo "$1" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}$' || fail "Formato invalido: '$1'. Use IP:PORTA (ex: 192.168.1.100:37123)"
}

echo
info "Wireless ADB (Android 11+, sem cabo/OTG, sem root)"
echo

LOCAL_IP="$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[0-9.]+' || true)"
if [ -n "$LOCAL_IP" ]; then
  info "Seu IP local: $LOCAL_IP"
fi

echo -e "${BLUE}No celular alvo:${NC} Ajustes > Opcoes do desenvolvedor > Depuracao wireless"
echo

read -rp "Ja pareou este dispositivo antes? [s/N] " PAIRED

if [ "$PAIRED" != "s" ] && [ "$PAIRED" != "S" ]; then
  echo
  step "Pareamento necessario"
  read -rp "IP:porta de pareamento (tela 'Parear com codigo'): " PAIR_ADDR
  validate_addr "$PAIR_ADDR"
  read -rp "Codigo de pareamento (6 digitos): " PAIR_CODE
  [ -z "$PAIR_CODE" ] && fail "Codigo nao pode ser vazio"
  info "Pareando..."
  timeout 15 termux-adb pair "$PAIR_ADDR" "$PAIR_CODE" || fail "Pareamento falhou (timeout 15s ou credenciais incorretas)"
  info "Pareado com sucesso"
fi

echo
read -rp "IP:porta de conexao (tela principal de depuracao wireless): " CONNECT_ADDR
validate_addr "$CONNECT_ADDR"

step "Conectando..."
timeout 15 termux-adb connect "$CONNECT_ADDR" || fail "Conexao falhou (timeout 15s). Verifique IP/porta e se depuracao wireless esta ativa."

echo
info "Conectado! Dispositivos:"
termux-adb devices
echo
