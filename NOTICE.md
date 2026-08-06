# Notice

Este repositório contém apenas scripts de instalação/desinstalação e documentação — nenhum código-fonte de terceiros é redistribuído aqui.

O pacote `termux-adb` instalado pelo `install.sh` é mantido de forma independente por **nohajc** em `https://github.com/nohajc/termux-adb` (MIT License) e distribuído pelo apt repo dele (`nohajc.github.io`). Todo o crédito pelo patch adb/fastboot + integração `termux-usb` é dele.

Ideias adicionais incorporadas neste projeto:

- Isolamento de dados do adb via `ANDROID_SDK_HOME` — inspirado na abordagem de **MasterDevX** (`https://github.com/MasterDevX/Termux-ADB`), reimplementada aqui usando a variável de ambiente oficialmente suportada pelo próprio adb.
- Padrão de distribuição via apt repo + gpg key — também usado por **rendiix** (`https://github.com/rendiix/termux-adb-fastboot`).

Nenhum binário, patch de código ou arquivo desses projetos foi copiado para este repositório.
