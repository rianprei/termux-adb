#!/system/bin/sh
# termux-adb: porta ADB fixa (5555) via root, sem toggle, sem porta TLS aleatoria.
# Roda em post-fs-data (antes do boot terminar) -- zero interacao, sempre ligado.
# Fonte da tecnica: pesquisa AOSP daemon/main.cpp (persist.adb.tcp.port com
# fallback service.adb.tcp.port) + ressalva SELinux (r/AndroidRoot) com
# fallback resetprop do Magisk. Ver context/termux-adb-research.md §10.1/§12.3.

PORT=5555
LOG=/data/local/tmp/termuxadb_rootport.log

echo "[$(date)] iniciando fix de porta" >> "$LOG"

setprop persist.adb.tcp.port "$PORT" 2>>"$LOG"
CURRENT=$(getprop persist.adb.tcp.port)

if [ "$CURRENT" != "$PORT" ]; then
    echo "[$(date)] setprop direto falhou (SELinux?), tentando resetprop" >> "$LOG"
    resetprop persist.adb.tcp.port "$PORT" 2>>"$LOG"
    CURRENT=$(getprop persist.adb.tcp.port)
fi

if [ "$CURRENT" = "$PORT" ]; then
    echo "[$(date)] OK: persist.adb.tcp.port=$CURRENT" >> "$LOG"
else
    echo "[$(date)] FALHOU: prop continua '$CURRENT', nem setprop nem resetprop pegaram" >> "$LOG"
fi
