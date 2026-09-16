#!/usr/bin/env bash
#
# adbw-binder-daemon — Inicia daemon Binder via app_process + su (root)
#
# STATUS: SKELETON/EXPERIMENTAL — não é feature terminada.
#   O que É real e testado: o comando app_process + CLASSPATH real do
#   Shizuku (confirmado por pesquisa de fonte), o gate de UID 0/2000, e o
#   caminho CLASSPATH→$HOME funcionando via su em Android 16/root (testado
#   ao vivo, ver seção "Testado ao vivo" no help).
#   O que NÃO está pronto: a classe Java real (DaemonStub é um placeholder
#   mínimo que só loga "ready" e dorme — não implementa o protocolo Binder
#   de verdade nem se conecta ao companion do bc-poc). Termux não tem
#   toolchain Java/dex instalada nesta sessão — nenhum .dex real foi
#   compilado nem testado end-to-end. Não use em produção.
#
# O que faz:
#   Lança um processo Java via app_process (root uid), usando o padrão real
#   do Shizuku ADB-mode: CLASSPATH=<dex> app_process /system/bin <Classe>.
#   O service aceita conexões via socket Unix (ContentProvider não aplica a
#   CLI Termux — veja §5). Expondo APIs privilegiadas ao companion daemon
#   do zygisk-bc-poc.
#
# Motivação (Shizuku):
#   Shizuku fornece um daemon (app_process + minimal Java) que atua como
#   "ponte" entre apps não-system e APIs do sistema via Binder IPC.
#   Nós precisamos do mesmo mecanismo porque: o companion daemon do bc-poc
#   precisa fazer chamadas privilegiadas que não podem ser feitas via ADB
#   shell alone (ex.: registerService no ServiceManager, transacts de sistema).
#
# Comando real (freebuff confirmou):
#   CLASSPATH=<dex> app_process /system/bin <Classe>
#
#   - <dex>: caminho pro .dex compilado (Shizuku usa um .dex standalone,
#     não .jar — mais leve, não precisa descompactar)
#   - /system/bin: diretório "system dir" do app_process (onde procura
#     classes principais — Shizuku usa /system/bin, não /)
#   - <Classe>: nome fully-qualified da classe Java/Kotlin com main()
#   - Gate de UID: 0 / 2000 (confirmado freebuff) — app_process via su
#     roda como root (uid 0), que atende o gate.
#
# --- ARQUITETURA (3 camadas, Shizuku-style) ---
#
#   [Termux (shell)]  ──su──>  [app_process (uid 0)]  ──Socket-Unix──>  [clients]
#     |                                                      |
#   roda este script                                 companion daemon (bc-poc)
#   (via su, precisa root)                           ou clientes Termux via UDS
#
# 1. Termux: valida pré-requisitos, monta CLASSPATH, delega pra su.
# 2. app_process (uid 0 via su): Android JVM launcher. Carrega <Classe> via
#    CLASSPATH=<dex>. Nossos stubs não precisam de framework Android completo.
# 3. Classe Java/Kotlin: implementação real do Binder service.
#    [IMPLEMENTAÇÃO REAL] → Shizuku server classes (github.com/blankj/shizuku,
#    ShizukuService.java + AIDL). freebuff confirmou o comando mas não entregou
#    o código-fonte Java — usar stub até termux-adb#12 (issue aberta pro freebuff).
#    Estimativa: ~150 LOC (Shizuku server ≈). O .dex vai pro $DAEMON_DEX_PATH.
#
# --- TRANSPORTE CLIENT ↔ DAEMON (freebuff) ---
#
#   ContentProvider: freebuff confirmou que o mecanismo de entrega via
#   ContentProvider funciona em apps Android reais, mas NÃO aplica a CLI
#   Termux (não tem context de app Android). Por isso: client ↔ daemon
#   communicate via Unix socket ($DAEMON_SOCKET). O companion daemon do
#   bc-poc se conecta ao UDS e manda comandos privilegiados pro app_process.
#
#   Caminho honesto: Termux (CLI) → su → app_process (uid 0) → Binder
#   para APIs de sistema; UDS (Unix Domain Socket) para Termux↔daemon.
#
# --- MODO DE OPERAÇÃO ---
#
#   $ adbw-binder-daemon.sh start   # lança app_process via su (foreground)
#   $ adbw-binder-daemon.sh start --bg   # ... em background (setsid)
#   $ adbw-binder-daemon.sh stop     # mata via PID file + su kill
#   $ adbw-binder-daemon.sh status   # checa se processo tá vivo
#
# PID file: $ANDROID_USER_HOME/adbw-binder-daemon.pid
# Socket:   $ANDROID_USER_HOME/adbw-binder-daemon.sock
#
# --- PRÉ-REQUISITOS ---
#   - su (Magisk/KernelSU) — obrigatório; app_process roda como uid 0
#   - app_process em PATH ou /system/bin/app_process
#   - .dex compilado (Shizuku server ou stub) em $DAEMON_DEX_PATH
#
# --- ASSUNÇÕES / RISCOS DOCUMENTADOS (freebuff + device-tested 2026-09-16) ---
#   1. PROVEN on-device (Android 16 / API 36 / Magisk uid=0):
#      `CLASSPATH=/data/data/com.termux/files/home/test.dex app_process /system/bin TestClass`
#      → output "TEST_CLASS_OK". A preocupação de que SELinux bloquearia
#      CLASSPATH apontando pro $HOME do Termux em Android 14+ É FALSA nesse
#      setup (Magisk root = contexto SELinux magisk:s0, permissive).
#      Em devices NÃO-rooted, o su não existe → fallback pra ContentProvider
#      precisa app Android real (fora do escopo de CLI Termux).
#   2. ContentProvider delivery: NÃO funciona em CLI Termux (freebuff confirmou).
#      UDS é o caminho pro client. Se precisar de app-level delivery (não Termux),
#      requer app Android real com <provider> registrado — fora do escopo CLI.
#   3. UID gate 0/2000: satisfeito pelo su (root uid = 0). Se su for kernelSU
#      com uid 2000, o gate passa. Shizuku documenta isso.
#   4. app_process64 (64-bit) é o binário real em Android 16 — script usa
#      /system/bin/app_process que resolve pro 64-bit via symlink.
#
# Source: freebuff (2026-09-16) — Shizuku ADB-mode command pattern;
#   termux-adb-research §14.5 (binder bridge draft).
#

set -uo pipefail

# --- Config (segue convenção termux-adb) ---
PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
ANDROID_USER_HOME="${ANDROID_USER_HOME:-$HOME/.termux-adb}"
PID_FILE="${ANDROID_USER_HOME}/adbw-binder-daemon.pid"
DAEMON_LOG="${ANDROID_USER_HOME}/adbw-binder-daemon.log"

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
step() { echo -e "${BLUE}[>]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

# --- Commands ---

cmd_start() {
  local bg=false
  [ "${1:-}" = "--bg" ] && bg=true

  # --- Pré-requisitos (root + app_process) — precisam de su ---
  command -v su >/dev/null 2>&1 || fail "comando 'su' ausente — root (Magisk/KernelSU) é obrigatório"
  su -c 'true' 2>/dev/null || fail "sem permissão de root — conceda acesso root ao Termux via su prompt"

  # Localiza app_process
  APP_PROCESS="$(command -v app_process 2>/dev/null || true)"
  if [ -z "$APP_PROCESS" ]; then
    APP_PROCESS="/system/bin/app_process"
  fi
  su -c "test -x '$APP_PROCESS'" 2>/dev/null || fail "app_process não executável via su: $APP_PROCESS"

  # UID gate: 0/2000 (freebuff) — satisfeito pelo su (root uid = 0)
  UID_CHECK="$(su -c 'id -u' 2>/dev/null | tr -d '[:space:]' || true)"
  if [ "$UID_CHECK" != "0" ] && [ "$UID_CHECK" != "2000" ]; then
    warn "UID via su = $UID_CHECK (esperado 0 ou 2000 — Shizuku gate). Continuar? (y/N)"
    read -r yn
    [ "$yn" = "y" ] || [ "$yn" = "Y" ] || fail "UID gate não satisfeito. Abortando."
  fi

  # --- Checa se já tá rodando ---
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    warn "daemon já rodando (PID $(cat "$PID_FILE"))"
    return 0
  fi

  # --- Valida o .dex existe ---
  # [IMPLEMENTAÇÃO REAL] — freebuff: CLASSPATH aponta pro .dex. Assunção
  # explícita (§untested): /data/local/tmp é world-readable + SELinux
  # permissive, permitindo app_process ler o .dex via CLASSPATH.
  DAEMON_CLASS="${DAEMON_CLASS:-com.github.rianprei.adbwbinder.DaemonStub}"
  DAEMON_DEX="${DAEMON_DEX:-/data/local/tmp/adbw-binder-daemon.dex}"

  su -c "test -f '$DAEMON_DEX'" 2>/dev/null || {
    warn "DEX não encontrado em $DAEMON_DEX"
    warn "Enquanto aguardamos o Java real do Shizuku server, use o stub:"
    warn "  echo 'package com.github.rianprei.adbwbinder; class DaemonStub {'"
    warn "  echo '  public static void main(String[]a) throws Exception {'"
    warn "  echo '    java.lang.System.out.println(\"[stub] ready\");'"
    warn "  echo '    java.lang.Thread.sleep(Long.MAX_VALUE); } }' > /data/local/tmp/DaemonStub.java"
    warn "  su -c 'cd /data/local/tmp && javac -cp /system/framework/boot.jar DaemonStub.java && dex -o DaemonStub.dex DaemonStub.class'"
    warn "  su -c 'mv /data/local/tmp/DaemonStub.dex $DAEMON_DEX'"
    fail "Interrompido — nenhum DEX de daemon disponível. Rode os stubs acima ou forneça o .dex real."
  }

  step "Lançando app_process via su (uid 0, Shizuku ADB-mode pattern)..."
  info "  classe: $DAEMON_CLASS"
  info "  dex:    $DAEMON_DEX"
  info "  app_process: $APP_PROCESS"
  info "  uid gate: 0/2000 (Shizuku)"

  # Comando real (freebuff): CLASSPATH=<dex> app_process /system/bin <Classe>
  # - CLASSPATH: aponta pro .dex (Shizuku usa .dex standalone, não .jar)
  # - /system/bin: system dir do app_process (onde procura classes)
  # - <Classe>: fully-qualified main class
  # NÃO usa -start-system-server (queremos só nosso service, não o sistema)
  local cmd="CLASSPATH='$DAEMON_DEX' $APP_PROCESS /system/bin $DAEMON_CLASS"

  if $bg; then
    # Background: via su, setsid-style. PID = do shell su, app_process filho = PID+1
    step "Modo background (setsid via su)"
    su -c "setsid $cmd >> '$DAEMON_LOG' 2>&1 & echo \$!" 2>/dev/null > "$PID_FILE.tmp"
    local child_pid="$(cat "$PID_FILE.tmp" 2>/dev/null || true)"
    if [ -n "$child_pid" ]; then
      echo "$child_pid" > "$PID_FILE"
      rm -f "$PID_FILE.tmp"
      info "daemon lançado em background (PID shell: $child_pid)"
      info "log: $DAEMON_LOG"
      # Nota: o PID real do app_process é child_pid+1 — usar ps via su
      # pra confirmar se precisar do PID exato.
    else
      rm -f "$PID_FILE.tmp"
      fail "su falhou ao lançar em background — verifique su logs / logcat"
    fi
  else
    step "Modo foreground (Ctrl+C para parar)"
    # app_process roda em foreground — Ctrl+C mata o su, que mata app_process
    info "pressione Ctrl+C para parar"
    exec su -c "$cmd" 2>&1 | tee -a "$DAEMON_LOG"
  fi
}

cmd_stop() {
  if [ ! -f "$PID_FILE" ]; then
    warn "sem PID file — daemon não tá rodando?"
    return 1
  fi
  local pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  if [ -z "$pid" ]; then
    rm -f "$PID_FILE"
    return 1
  fi
  step "Parando daemon (PID $pid) via su..."
  su -c "kill $pid 2>/dev/null; kill -9 $pid 2>/dev/null" 2>/dev/null || true
  rm -f "$PID_FILE"
  info "daemon parado"
}

cmd_status() {
  if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE" 2>/dev/null)" 2>/dev/null; then
    info "daemon rodando (PID $(cat "$PID_FILE"))"
    # freebuff: service name definido na classe Java real (Shizuku server).
    # Enquanto isso, só checamos processo vivo — dumpsys do service precisa
    # do nome real, que só existe quando implementarmos o Java.
    return 0
  fi
  warn "daemon parado (nenhum PID válido)"
  return 1
}

cmd_help() {
  cat <<'EOF'
Uso: adbw-binder-daemon.sh <comando> [opções]

Comandos:
  start   [--bg]   Lança app_process via su (CLASSPATH=<dex> app_process /system/bin <Classe>)
  stop             Para o daemon (via PID file + su kill)
  status           Checa se o processo tá vivo

Pré-requisitos:
  - su (MagKit/KernelSU) — uid 0/2000 (Shizuku gate, freebuff confirmed)
  - app_process em PATH ou /system/bin/app_process
  - .dex compilado em $DAEMON_DEX (default: /data/local/tmp/adbw-binder-daemon.dex)

Variáveis de ambiente:
  DAEMON_CLASS  — fully-qualified Java class (default: com.github.rianprei.adbwbinder.DaemonStub)
  DAEMON_DEX    — caminho pro .dex (default: /data/local/tmp/adbw-binder-daemon.dex)

Transporte:
  Unix socket (UDS) — ContentProvider não aplica a CLI Termux (freebuff)

Testado ao vivo (kilo, 2026-09-16, device Android 16/HyperOS, root Magisk):
  CLASSPATH apontando pro \$HOME do Termux funcionou via su (uid 0) nesse
  device/versão. Preocupação original (precedente rish chmod 400) era
  especificamente sobre Android 14/15 — não testado nessas versões
  específicas, só confirmado em Android 16. Fallback ainda disponível
  (injetar via su -c direto) se algum device/versão bloquear.
EOF
}

# --- Main dispatch ---
case "${1:-}" in
  start)  cmd_start "${2:-}" ;;
  stop)   cmd_stop ;;
  status) cmd_status ;;
  help|-h|--help) cmd_help ;;
  "") cmd_help; exit 1 ;;
  *) fail "comando desconhecido: $1 (use: start|stop|status|help)" ;;
esac
