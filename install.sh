#!/data/data/com.termux/files/usr/bin/bash
set -e

SUPPORTED_ARCHS="aarch64 arm x86_64 i686"
ARCH="$(uname -m)"
case " $SUPPORTED_ARCHS " in
  *" $ARCH "*) ;;
  *)
    echo "Arquitetura '$ARCH' pode nao ser suportada pelo repo termux-adb." >&2
    echo "Arquiteturas conhecidas: $SUPPORTED_ARCHS" >&2
    ;;
esac

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install coreutils gnupg wget

if ! command -v termux-usb >/dev/null 2>&1; then
  echo "termux-usb nao encontrado. Instalando termux-api (necessario para USB sem root)..."
  apt-get --assume-yes install termux-api
  echo "Instale tambem o app Termux:API (F-Droid) se ainda nao instalado."
fi

if [ ! -f "$PREFIX/etc/apt/sources.list.d/termux-adb.list" ]; then
  mkdir -p "$PREFIX/etc/apt/sources.list.d"
  echo "deb https://nohajc.github.io termux extras" > "$PREFIX/etc/apt/sources.list.d/termux-adb.list"
  wget -qP "$PREFIX/etc/apt/trusted.gpg.d" https://nohajc.github.io/nohajc.gpg
  apt update
else
  echo "Repo already installed"
fi

apt-get --assume-yes install termux-adb

echo "done!"
