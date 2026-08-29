# Notice

Os pacotes `.deb` de `termux-adb` e `termux-fastboot` redistribuídos neste repositório
(via GitHub Releases) foram originalmente compilados e publicados por **nohajc** em
`https://github.com/nohajc/termux-adb` sob licença **MIT** (Copyright 2022 nohajc).
Todo o crédito pelo patch adb/fastboot + integração `termux-usb` é dele. Os binários
são redistribuídos aqui sob os mesmos termos da licença MIT original, para garantir
disponibilidade independente do repositório upstream.

Ideias adicionais incorporadas neste projeto:

- Isolamento de dados do adb via `ANDROID_USER_HOME` — inspirado na abordagem de
  **MasterDevX** (`https://github.com/MasterDevX/Termux-ADB`), reimplementada usando a
  variável de ambiente oficial do adb.
- Conceito de instalação em um comando — popularizado por **MasterDevX**.
- Padrão de distribuição confiável — também validado por **rendiix**
  (`https://github.com/rendiix/termux-adb-fastboot`).
- Conceito de auto-updater (`termux-adb-update`) — de **offici5l**
  (`https://github.com/offici5l/termux-adb-fastboot`), reimplementado do zero.

Os front-ends `adb`/`fastboot` com roteamento automático de backend, o watcher OTG
(`adb-otg-watcher`) e as ferramentas `adbs`, `adbw`, `adbmenu`, `adbpair`, `adbotg` e
`adblocalhost` são **originais deste projeto** (licença MIT, Copyright 2026 rianprei).

Integrações opcionais (não redistribuídas — dependem de instalação separada):

- **scrcpy** (`https://github.com/Genymobile/scrcpy`) — espelhamento de tela.
- **ADBash** (`https://github.com/BuriXon-code/ADBash`) — shell Bash na sessão ADB local.