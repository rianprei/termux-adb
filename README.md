# termux-adb

ADB e Fastboot no Termux **sem root**, com repo apt mantido (updates via `pkg upgrade`), config isolada do `$HOME`, checagem de arquitetura, auto-instalação do `termux-api`, uninstall limpo e modo wireless (sem cabo OTG).

Testado 100% funcional em Termux (aarch64), 2026-08-06 — ver [CHANGELOG.md](CHANGELOG.md).

## Instalação

- instale Termux e Termux:API (F-Droid)
- no Termux:

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/install.sh | bash
```

O script:
- confere sua arquitetura (`aarch64`, `arm`, `x86_64`, `i686`)
- instala `termux-api` automaticamente se faltar (necessário pro USB sem root)
- adiciona o repo apt + chave gpg e instala `termux-adb`/`termux-fastboot`
- isola os dados do adb (chaves, cache) em `~/.termux-adb`, fora do `$HOME` do Termux
- para no primeiro erro (`set -e`), nunca finge sucesso

Updates futuros: `pkg upgrade`.

## Uso

`termux-adb` e `termux-fastboot` são drop-in replacements dos comandos originais — mesma sintaxe do `adb`/`fastboot` padrão. Nomes trocados só pra não colidir com o pacote `android-tools` do Termux.

### USB (cabo/OTG)

```
termux-adb devices
```

Na primeira execução o Android vai pedir permissão de acesso USB — aceite.

### Wireless (Android 11+, sem cabo)

```
bash wireless-adb.sh
```

Guia interativo de pareamento/conexão via depuração wireless.

## Desinstalar

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/uninstall.sh | bash
```

Remove pacote, repo apt, chave gpg e config isolada (`~/.termux-adb`).

## Como funciona

Termux tem `android-tools` (adb/fastboot padrão), mas ele só funciona com root — falta permissão de filesystem pra varrer `/dev/bus/usb/*`. O termux-adb usa a API `termux-usb` do Termux:API pra obter o file descriptor de qualquer dispositivo USB conectado, após aprovação manual do usuário. Os binários adb/fastboot são patchados pra pedir esse descriptor via `termux-usb` em vez de acessar `/dev/bus/usb` direto, e um Unix Domain Socket transfere o descriptor entre processos — funciona com qualquer número de dispositivos (ex: hub USB no adaptador OTG).

## Limitações conhecidas

Consultar o serial do dispositivo via `libusb`/`termux-usb` é lento. Isso não afeta o adb (roda como daemon, varre periodicamente), mas é perceptível no fastboot (sem serviço em background).

## Créditos

Este projeto reúne, de forma independente, as melhores ideias do ecossistema de ADB sem root no Termux:

- **[nohajc/termux-adb](https://github.com/nohajc/termux-adb)** — o patch adb/fastboot + `termux-usb` que permite USB sem root, distribuído via apt repo próprio. Núcleo técnico usado aqui.
- **[MasterDevX/Termux-ADB](https://github.com/MasterDevX/Termux-ADB)** — popularizou a instalação em 1 comando e a ideia de isolar dados do adb fora do `$HOME` (aqui implementado via `ANDROID_SDK_HOME`, oficialmente suportado pelo próprio adb).
- **[rendiix/termux-adb-fastboot](https://github.com/rendiix/termux-adb-fastboot)** — validou o padrão de distribuição via apt repo + gpg key própria.

Ver [NOTICE.md](NOTICE.md) para detalhes de atribuição.
