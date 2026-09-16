#!/data/data/com.termux/files/usr/bin/bash
#
# adbw-root-porta — porta fixa de ADB wireless via root (item 1 da §12.5)
#
# O que faz: grava persist.adb.tcp.port=<porta> (default 5555) e reinicia o
# adbd para que ele escute nessa porta de forma PERMANENTE (sobrevive a reboot,
# sem mDNS, sem porta aleatória). Fonte do mecanismo: adbd lê
# service.adb.tcp.port → fallback persist.adb.tcp.port (AOSP daemon/main.cpp:275-277).
#
# Estratégia (§12.3 e §10.1 de termux-adb-research):
#   1. setprop persist.adb.tcp.port <porta>   — caminho oficial (pode ser negado por SELinux)
#   2. fallback: resetprop <porta>            — Magisk resetprop bypassa o property_service
#   3. validação: getprop antes/depois; se a prop não grudar, erro com diagnóstico
#
# AVISO: o modo tcp: porta fixa é plaintext+RSA (não é o TLS do wireless A11+).
# Use apenas em rede confiável — ver docs/SEGURANCA.md.

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BLUE='\033[0;34m'; NC='\033[0m'
info() { echo -e "${GREEN}[*]${NC} $1"; }
fail() { echo -e "${RED}[✗]${NC} $1" >&2; exit 1; }
step() { echo -e "${BLUE}[>]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }

PORT="${1:-5555}"
echo "$PORT" | grep -qE '^[0-9]{1,5}$' || fail "Porta inválida: '$PORT' (use número, ex: 5555)"
[ "$PORT" -ge 1024 ] && [ "$PORT" -le 65535 ] || fail "Porta fora do intervalo 1024-65535: $PORT"

# 0. Pré-requisitos: root
command -v su >/dev/null 2>&1 || fail "comando 'su' ausente — root (Magisk/KernelSU) é obrigatório pra este script"
su -c 'true' 2>/dev/null || fail "sem permissão de root (conceda acesso ao su para o Termux)"
command -v getprop >/dev/null 2>&1 || fail "getprop ausente (rode dentro do Termux num Android real)"

PROP="persist.adb.tcp.port"

echo
info "Porta fixa de ADB via root — alvo: $PORT"
echo

# 1. Estado antes
BEFORE="$(su -c "getprop $PROP" 2>/dev/null || true)"
if [ -n "$BEFORE" ]; then
  info "Estado atual: $PROP=$BEFORE"
else
  info "Estado atual: $PROP não definida"
fi

# 2. Tentativa 1 — setprop oficial
step "Tentando setprop $PROP $PORT..."
su -c "setprop $PROP $PORT" 2>/dev/null
AFTER="$(su -c "getprop $PROP" 2>/dev/null || true)"

# 3. Fallback — resetprop do Magisk (bypassa o property_service/SELinux check)
#    Nota: resetprop pode não estar no PATH do Termux, mas existe no ambiente
#    do su (Magisk) — por isso tentamos via su, não via command -v.
if [ "$AFTER" != "$PORT" ]; then
  warn "setprop não grudou (provável AVC denial do init — esperado em builds novos, §10.1)"
  step "Tentando resetprop via su (Magisk)..."
  if su -c "resetprop $PROP $PORT" 2>/dev/null; then
    AFTER="$(su -c "getprop $PROP" 2>/dev/null || true)"
  else
    warn "resetprop indisponível ou negado (Magisk ausente? su não expõe resetprop?)"
  fi
fi

[ "$AFTER" = "$PORT" ] || fail "Não consegui gravar $PROP (antes='$BEFORE' depois='$AFTER').
Diagnóstico:
  - Confirme que o su concedeu acesso root ao Termux
  - Com Magisk: garanta que o módulo/su binary expõe resetprop
  - Sem resetprop, resta editar /data/property/persistent_properties (NÃO recomendado)"

info "Prop gravada: $PROP=$AFTER"

# 4. Aplicar agora — reiniciar adbd (a prop é lida no boot do adbd)
step "Reiniciando adbd (setprop ctl.restart adbd)..."
if ! su -c "setprop ctl.restart adbd" 2>/dev/null; then
  warn "ctl.restart falhou (SELinux pode negar ctl em domínio su) — tentando stop/start"
  su -c "stop adbd" 2>/dev/null; sleep 1
  su -c "start adbd" 2>/dev/null || warn "start adbd falhou; a porta fixa vale a partir do próximo reboot"
fi
sleep 2

# 5. Validação final: adbd escutando na porta?
LISTENING="$(netstat -tln 2>/dev/null | grep -c ":$PORT " || true)"
if [ "$LISTENING" -gt 0 ]; then
  info "adbd escutando na porta $PORT ✓"
  echo
  info "Pronto. Conecte de qualquer host da rede: adb connect <IP-do-aparelho>:$PORT"
  info "A configuração persiste após reboot (persist.). Para reverter: su -c 'resetprop $PROP \"\"; stop adbd; start adbd'"
else
  warn "Não confirmei escuta na porta $PORT agora (netstat), mas a prop está gravada:"
  warn "a porta fixa vale a partir do próximo reboot. Valide com: getprop $PROP"
fi
