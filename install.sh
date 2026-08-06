#!/data/data/com.termux/files/usr/bin/bash
set -e

SUPPORTED_ARCHS="aarch64 arm x86_64 i686"
ARCH="$(uname -m)"
case " $SUPPORTED_ARCHS " in
  *" $ARCH "*) ;;
  *)
    echo "Arquitetura '$ARCH' pode nao ser suportada." >&2
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
  echo "Repo ja instalado"
fi

apt-get --assume-yes install termux-adb

# Isola dados do adb (~/.android) fora do $HOME do Termux
mkdir -p "$HOME/.termux-adb"
for RC in "$HOME/.bashrc" "$HOME/.zshrc"; do
  [ -f "$RC" ] || continue
  grep -q "ANDROID_SDK_HOME=.*\.termux-adb" "$RC" 2>/dev/null || \
    echo 'export ANDROID_SDK_HOME="$HOME/.termux-adb"' >> "$RC"
done
export ANDROID_SDK_HOME="$HOME/.termux-adb"

echo "done!"
