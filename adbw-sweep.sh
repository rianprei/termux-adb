#!/data/data/com.termux/files/usr/bin/bash
#
# adbw-sweep — descoberta de porta dinâmica ADB wireless sem root (item 5 da §12.5)
#
# Substitui o `adb mdns services`, que NÃO existe no binário android-tools do
# Termux (build nmeum compila com ANDROID_TOOLS_ADB_ENABLE_MDNS=OFF — §12.1 do
# research). Varre o range efêmero TLS 32768-60999 com nmap e tenta adb connect
# em cada porta aberta até virar transporte "device".
#
# Uso: adbw-sweep <IP>          # varre e conecta
#      adbw-sweep <IP> --dry    # só lista portas abertas, não conecta
#
# A porta achada é gravada no ~/.cache/adbw-state (mesmo arquivo do --watch),
# então o watch passa a tentá-la primeiro.

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

command -v adb >/dev/null 2>&1 || fail "adb ausente — instale: pkg install android-tools"
command -v nmap >/dev/null 2>&1 || fail "nmap ausente — instale: pkg install nmap"

IP="${1:-}"
DRY="${2:-}"
[ -n "$IP" ] || { sed -n '2,16p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
echo "$IP" | grep -qE '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$' || fail "IP inválido: '$IP'"

info "Varrendo $IP (32768-60999, porta TLS dinâmica do wireless debugging A11+)..."
PORTS="$(nmap -p 32768-60999 --open -T4 "$IP" -oG - 2>/dev/null | grep -oE '[0-9]+/open' | cut -d/ -f1 | sort -n)"

if [ -z "$PORTS" ]; then
  fail "nenhuma porta aberta no range. Verifique: depuração wireless ligada? IP correto? mesma rede?"
fi

N=$(echo "$PORTS" | wc -l)
info "porta(s) aberta(s): $(echo $PORTS | tr '\n' ' ') ($N)"

if [ "$DRY" = "--dry" ]; then
  info "--dry: sem conexão. Tente: adbw-sweep $IP (sem --dry)"
  exit 0
fi

STATE="${HOME}/.cache/adbw-state"
for P in $PORTS; do
  info "tentando adb connect $IP:$P..."
  timeout 8 adb connect "$IP:$P" >/dev/null 2>&1
  if adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {found=1} END {exit !(found)}'; then
    info "conectado em $IP:$P ✓"
    mkdir -p "$(dirname "$STATE")"
    printf 'addr=%s:%s\nlast_seen=%s\n' "$IP" "$P" "$(date +%s)" > "$STATE"
    info "gravado em $STATE — adbw --watch passa a tentar essa porta primeiro"
    adb devices
    exit 0
  fi
done

fail "portas abertas encontradas ($PORTS) mas nenhuma virou transporte adb device —
pode ser outro serviço escutando; confirme que a Depuração wireless está ativa"
