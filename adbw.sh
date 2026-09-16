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

# -----------------------------------------------------------------------------
# adbw --watch — loop de reconexão automática (item 2 da §12.5)
#
# Backoff 3s→30s (exponencial, cap 30s). Estado em ~/.cache/adbw-state:
#   addr=<ip:porta>    última porta conhecida (tentada primeiro a cada ciclo)
#   last_seen=<epoch>  última vez que o transporte respondeu
#
# Com porta fixa (adbw-root-porta.sh), o addr é sempre ip:5555 e a reconexão
# vira trivia. Sem root, tenta a porta conhecida e, a cada 5 falhas seguidas,
# faz sweep nmap no range dinâmico (32768-60999) se nmap estiver instalado
# (o binário android-tools do Termux NÃO tem mDNS — ver §12.1 do research).
# -----------------------------------------------------------------------------
STATE_FILE="${HOME}/.cache/adbw-state"
WATCH_INTERVAL_MIN=3
WATCH_INTERVAL_MAX=30

watch_load_state() {
  addr=""; last_seen=0
  [ -f "$STATE_FILE" ] || return 0
  # shellcheck disable=SC1090
  . "$STATE_FILE"
  W_ADDR="${addr:-}"
  W_LAST_SEEN="${last_seen:-0}"
}

watch_save_state() {
  mkdir -p "$(dirname "$STATE_FILE")"
  cat > "$STATE_FILE" <<EOF
addr=$W_ADDR
last_seen=$W_LAST_SEEN
EOF
}

watch_is_connected() {
  adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit !(found)}'
}

watch_try_connect() {
  [ -n "${W_ADDR:-}" ] || return 1
  timeout 8 adb connect "$W_ADDR" >/dev/null 2>&1
  watch_is_connected
}

watch_sweep() {
  command -v nmap >/dev/null 2>&1 || { info "nmap ausente (pkg install nmap) — sweep indisponível"; return 1; }
  [ -n "${W_IP:-}" ] || return 1
  info "Sweep nmap em $W_IP (porta dinâmica TLS 32768-60999)..."
  local PORTS
  PORTS="$(nmap -p 32768-60999 --open -T4 "$W_IP" -oG - 2>/dev/null | grep -oE '[0-9]+/open' | cut -d/ -f1)"
  [ -z "$PORTS" ] && { info "nenhuma porta aberta encontrada no range"; return 1; }
  local P
  for P in $PORTS; do
    W_ADDR="$W_IP:$P"
    info "tentando $W_ADDR..."
    if watch_try_connect; then return 0; fi
  done
  return 1
}

watch_loop() {
  W_IP="${1:-}"
  W_PORT="${2:-}"
  watch_load_state

  # Módulo Magisk termuxadb_rootport detectado? → porta fixa 5555 sempre primeiro
  # (o módulo grava persist.adb.tcp.port=5555 no boot — ver README 'Modo root')
  ROOT_PORT="$(getprop persist.adb.tcp.port 2>/dev/null || true)"
  if [ -n "$ROOT_PORT" ] && [ "$ROOT_PORT" != "" ]; then
    if [ -n "$W_IP" ]; then
      W_ADDR="$W_IP:$ROOT_PORT"
      info "módulo Magisk detectado (persist.adb.tcp.port=$ROOT_PORT) — usando porta fixa"
    elif [ -n "${W_ADDR:-}" ] && [ "${W_ADDR##*:}" != "$ROOT_PORT" ]; then
      W_ADDR="${W_ADDR%%:*}:$ROOT_PORT"
      info "módulo Magisk detectado — reescrevendo addr pra porta fixa: $W_ADDR"
    fi
  fi

  if [ -n "$W_IP" ] && [ -n "$W_PORT" ]; then
    W_ADDR="$W_IP:$W_PORT"
  elif [ -z "${W_ADDR:-}" ]; then
    echo -e "${YELLOW}[!]${NC} sem estado prévio. Use: adbw --watch <IP> [PORTA] (uma vez)"
    echo -e "${YELLOW}[!]${NC} com módulo Magisk/porta fixa: adbw --watch <IP> (a porta vem da prop)"
    echo -e "${YELLOW}[!]${NC} sem root: a PORTA dinâmica é obrigatória na 1ª vez (fica gravada pro próximo ciclo)"
    exit 1
  fi

  if [ -z "$W_IP" ]; then
    W_IP="${W_ADDR%%:*}"
  fi

  info "watch iniciado: addr=$W_ADDR (estado em $STATE_FILE)"
  info "Ctrl+C encerra. Backoff ${WATCH_INTERVAL_MIN}s→${WATCH_INTERVAL_MAX}s"

  local INTERVAL=$WATCH_INTERVAL_MIN
  local FAILS=0
  while true; do
    if watch_is_connected; then
      W_LAST_SEEN="$(date +%s)"
      watch_save_state
      INTERVAL=$WATCH_INTERVAL_MIN
      FAILS=0
      sleep "$INTERVAL"
      continue
    fi

    FAILS=$((FAILS + 1))
    info "sem transporte device (falha #$FAILS) — tentando reconnect em $W_ADDR..."

    if watch_try_connect; then
      W_LAST_SEEN="$(date +%s)"
      watch_save_state
      info "reconectado em $W_ADDR ✓"
      INTERVAL=$WATCH_INTERVAL_MIN
      FAILS=0
    elif watch_sweep; then
      W_LAST_SEEN="$(date +%s)"
      watch_save_state
      info "reconectado via sweep em $W_ADDR ✓"
      INTERVAL=$WATCH_INTERVAL_MIN
      FAILS=0
    else
      INTERVAL=$((INTERVAL * 2))
      [ "$INTERVAL" -gt "$WATCH_INTERVAL_MAX" ] && INTERVAL=$WATCH_INTERVAL_MAX
      info "falhou; próximo ciclo em ${INTERVAL}s"
    fi

    sleep "$INTERVAL"
  done
}

# roteamento: adbw --watch [IP] [PORTA]
if [ "${1:-}" = "--watch" ]; then
  shift
  watch_loop "$@"
fi

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

# grava estado pro --watch (item 2): addr conhecido + last_seen
mkdir -p "$HOME/.cache"
printf 'addr=%s\nlast_seen=%s\n' "$CONNECT_ADDR" "$(date +%s)" > "$HOME/.cache/adbw-state"

echo
info "Conectado. Dispositivos:"
adb devices
echo
echo "Observação: se o dispositivo ficar offline, execute 'adb kill-server' e reconecte."
echo "            A porta de conexão muda a cada reinicialização; o pareamento é único."