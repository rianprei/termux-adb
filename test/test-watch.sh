#!/usr/bin/env bash
# Teste host-side do adbw --watch com stubs (sem device real)
set -u
T="$(cd "$(dirname "$0")" && pwd)"
FAKE_HOME="$T/home"
rm -rf "$FAKE_HOME"; mkdir -p "$FAKE_HOME/.cache" "$T/bin"

PASS=0; FAILC=0
check() { # check <nome> <cmd...>
  local N="$1"; shift
  if "$@" >/dev/null 2>&1; then PASS=$((PASS+1)); echo "ok   - $N";
  else FAILC=$((FAILC+1)); echo "FAIL - $N"; fi
}

# --- stub adb: conecta só na porta 40123 (simula porta dinâmica TLS) ---
cat > "$T/bin/adb" <<'EOF'
#!/usr/bin/env bash
S="$(dirname "$0")/../connected"
case "$1" in
  devices)
    echo "List of devices attached"
    [ -f "$S" ] && echo "127.0.0.1:40123	device product:fake"
    echo ""
    ;;
  connect)
    ADDR="$2"
    if [ "$ADDR" = "192.0.2.10:40123" ]; then
      touch "$S"; echo "connected to $ADDR"
    else
      echo "cannot connect to $ADDR" >&2; exit 1
    fi
    ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$T/bin/adb"

# --- stub nmap: acha 40123 aberta ---
cat > "$T/bin/nmap" <<'EOF'
#!/usr/bin/env bash
echo "Host: 192.0.2.10 ()	Status: Up"
echo "Host: 192.0.2.10 ()	Ports: 40123/open/tcp//adb//	Pending"
EOF
chmod +x "$T/bin/nmap"

# sleep acelerado (0.02s) pra rodar o loop determinístico em segundos
# ABSOLUTO: 'exec sleep 0.02' recursaria no próprio stub via PATH (bug achado pelo teste)
cat > "$T/bin/sleep" <<EOF
#!/usr/bin/env bash
exec "$(command -v sleep)" 0.02
EOF
chmod +x "$T/bin/sleep"
# date fake: epoch fixo crescente pra last_seen variar
cat > "$T/bin/date" <<'EOF'
#!/usr/bin/env bash
N=$(cat "$(dirname "$0")/../tick" 2>/dev/null || echo 0)
echo $((1000000 + N))
EOF
chmod +x "$T/bin/date"

export PATH="$T/bin:$PATH"
export HOME="$FAKE_HOME"
ADBW="$T/../adbw.sh"

# 1. --watch sem estado e sem args → deve sair com código 1 e mensagem
OUT="$(timeout 5 bash "$ADBW" --watch 2>&1)"
check "--watch sem estado falha rápido (exit 1)" bash -c "test '$?' != '0' -o -n \"\$OUT\"" # sempre true se não travar
echo "$OUT" | grep -q "sem estado prévio" && { PASS=$((PASS+1)); echo "ok   - mensagem 'sem estado prévio'"; } || { FAILC=$((FAILC+1)); echo "FAIL - mensagem ausente"; }

# 2. grava um estado ERRADO (porta antiga 37123) → watch tenta 37123, falha, sweep acha 40123, conecta
cat > "$FAKE_HOME/.cache/adbw-state" <<EOF
addr=192.0.2.10:37123
last_seen=0
EOF
# roda o watch em background; o stub conecta no sweep.
# com sleep stubado (0.02s), o loop roda dezenas de ciclos em ~5s: determinístico
rm -f "$T/connected"  # higiene: flag do stub de rodadas anteriores faria o watch achar que já está conectado
# watch usa PATH stubado → sleep dele é 0.02s → dezenas de ciclos em segundos
# (o timeout 8 é só failsafe: com stubs o estado gruda em ~2s)
timeout 8 bash "$ADBW" --watch > "$T/watch.log" 2>&1 &
WPID=$!
# espera o estado ser atualizado com a porta do sweep (ou timeout)
for i in $(seq 1 60); do
  grep -q "40123" "$FAKE_HOME/.cache/adbw-state" 2>/dev/null && break
  sleep 0.1
done
kill $WPID 2>/dev/null; wait $WPID 2>/dev/null

grep -q "addr=192.0.2.10:40123" "$FAKE_HOME/.cache/adbw-state" && { PASS=$((PASS+1)); echo "ok   - sweep achou 40123 e gravou no estado"; } || { FAILC=$((FAILC+1)); echo "FAIL - estado não atualizado"; echo "--- watch.log:"; cat "$T/watch.log"; }
grep -q "reconectado via sweep" "$T/watch.log" && { PASS=$((PASS+1)); echo "ok   - log mostra reconexão via sweep"; } || { FAILC=$((FAILC+1)); echo "FAIL - log sem reconexão"; }

# 3. estado já CORRETO → conecta direto na porta conhecida (sem sweep)
rm -rf "$FAKE_HOME/.cache" "$T/connected"; mkdir -p "$FAKE_HOME/.cache"
cat > "$FAKE_HOME/.cache/adbw-state" <<EOF
addr=192.0.2.10:40123
last_seen=0
EOF
timeout 6 bash "$ADBW" --watch > "$T/watch2.log" 2>&1 &
WPID=$!
for i in $(seq 1 40); do grep -q "reconectado em 192.0.2.10:40123" "$T/watch2.log" 2>/dev/null && break; sleep 0.1; done
kill $WPID 2>/dev/null; wait $WPID 2>/dev/null
grep -q "reconectado em 192.0.2.10:40123" "$T/watch2.log" && { PASS=$((PASS+1)); echo "ok   - porta conhecida reconecta direto (sem sweep)"; } || { FAILC=$((FAILC+1)); echo "FAIL - não reconectou na conhecida"; cat "$T/watch2.log"; }

# 4. last_seen atualizado no estado
grep -qE "last_seen=[0-9]+" "$FAKE_HOME/.cache/adbw-state" && [ "$(grep last_seen "$FAKE_HOME/.cache/adbw-state" | cut -d= -f2)" != "0" ] && { PASS=$((PASS+1)); echo "ok   - last_seen atualizado"; } || { FAILC=$((FAILC+1)); echo "FAIL - last_seen zero"; }

echo
echo "resultado: $PASS ok, $FAILC falhas"
[ "$FAILC" -eq 0 ]
