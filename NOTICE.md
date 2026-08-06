# Notice

Os pacotes `.deb` de `termux-adb` e `termux-fastboot` redistribuídos neste repositório (via GitHub Releases) foram originalmente compilados e publicados por **nohajc** em `https://github.com/nohajc/termux-adb` sob licença **MIT** (Copyright 2022 nohajc). Todo o crédito pelo patch adb/fastboot + integração `termux-usb` é dele. Os binários são redistribuídos aqui sob os mesmos termos da licença MIT original, para garantir disponibilidade independente do repo upstream.

Ideias adicionais incorporadas neste projeto:

- Isolamento de dados do adb via `ANDROID_USER_HOME` — inspirado na abordagem de **MasterDevX** (`https://github.com/MasterDevX/Termux-ADB`), reimplementada usando a variável de ambiente oficial do adb.
- Conceito de instalação silenciosa em 1 comando — popularizado por **MasterDevX**.
- Padrão de distribuição confiável — também validado por **rendiix** (`https://github.com/rendiix/termux-adb-fastboot`).
- Symlinks `adb`→`termux-adb` e conceito de auto-updater (`termux-adb-u`) — de **offici5l** (`https://github.com/offici5l/termux-adb-fastboot`), reimplementado do zero.

Scripts, documentação, ferramentas extras (wireless-adb, termux-adb-doctor) e toda a infraestrutura de instalação são originais deste projeto.
