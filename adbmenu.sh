#!/data/data/com.termux/files/usr/bin/bash
#
# adbmenu — menu interativo das ferramentas ADB.
# Uso: adbmenu   (sem argumentos)

set -uo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
NATIVE_ADB="$PREFIX/bin/adb"

banner() {
  echo -e "${BLUE}"
  echo
  echo "   █████╗ ██████╗ ██████╗     ███╗   ███╗██╗   ██╗██╗  ████████╗██╗   ██╗███████╗██████╗ ███████╗ ███████╗"
  echo "  ██╔══██╗██╔══██╗██╔══██╗    ████╗ ████║██║   ██║██║  ╚══██╔══╝██║   ██║██╔════╝██╔══██╗██╔════╝ ██╔════╝"
  echo "  ███████║██║  ██║██████╔╝    ██╔████╔██║██║   ██║██║     ██║   ██║   ██║█████╗  ██████╔╝███████╗ █████╗  "
  echo "  ██╔══██║██║  ██║██╔═══╝     ██║╚██╔╝██║██║   ██║██║     ██║   ██║   ██║██╔══╝  ██╔══██╗╚════██║ ██╔══╝  "
  echo "  ██║  ██║██████╔╝██║         ██║ ╚═╝ ██║╚██████╔╝███████╗██║   ╚██████╔╝███████╗██║  ██║███████║ ███████╗"
  echo "  ╚═╝  ╚═╝╚═════╝ ╚═╝         ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝    ╚═════╝ ╚══════╝╚═╝  ╚═╝╚══════╝ ╚══════╝"
  echo
  echo -e "${NC}${GREEN}Termux ADB — sem root, sem bootloader${NC}"
  echo
}

menu() {
  echo "Selecione uma opção:"
  echo "  1) Conectar wireless (outro aparelho, Android 11+)  [adbw]"
  echo "  2) Conectar no próprio aparelho (localhost)         [adblocalhost]"
  echo "  3) Listar dispositivos USB OTG                      [adbotg]"
  echo "  4) Status dos dispositivos                          [adb devices -l]"
  echo "  5) Shell Android                                    [adb shell]"
  echo "  6) Espelhar tela via scrcpy"
  echo "  7) Shell Bash na sessão ADB                         [ADBash.sh]"
  echo "  8) Instalar APK                                     [adb install]"
  echo "  9) Baixar arquivo                                   [adb pull]"
  echo " 10) Enviar arquivo                                   [adb push]"
  echo " 11) Diagnóstico completo                             [adbs]"
  echo " 12) Parear novo aparelho                             [adbpair]"
  echo "  q) Sair"
  echo
}

assure_device() {
  if ! "$NATIVE_ADB" devices 2>/dev/null | grep -qE "^([0-9]|.*device)"; then
    echo -e "${YELLOW}[!]${NC} Nenhum dispositivo conectado."
    read -rp "Conectar primeiro? (1=wireless, 2=localhost, Enter=continuar) " A
    case "$A" in
      1) adbw ;;
      2) adblocalhost ;;
      *) echo "Continuando..." ;;
    esac
  fi
}

loop() {
  while :; do
    menu
    read -rp "Opção: " OP
    case "$OP" in
      1) adbw ;;
      2) adblocalhost ;;
      3) adbotg ;;
      4) adb devices -l ;;
      5) assure_device; adb shell ;;
      6) assure_device; scrcpy ;;
      7) assure_device; ADBash.sh ;;
      8) read -rp 'Caminho do APK: ' figu; adb install "$figu" ;;
      9) read -rp 'Arquivo no aparelho: ' origem; adb pull "$origem" ;;
     10) read -rp 'Arquivo local: ' origem; adb push "$origem" /sdcard/ ;;
     11) adbs ;;
     12) adbpair ;;
     q|Q) echo -e "${GREEN}Encerrado.${NC}"; exit 0 ;;
      *) echo -e "${RED}Opção inválida.${NC}" ;;
    esac
  done
}

banner
loop