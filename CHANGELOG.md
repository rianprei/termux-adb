# Changelog

## [2.0.0] - 2026-08-06

Projeto reestruturado como independente (não mais enquadrado como fork). Núcleo técnico (patch adb/fastboot + termux-usb) continua vindo do apt repo do nohajc; scripts, docs e melhorias abaixo são deste projeto. Ver [NOTICE.md](NOTICE.md).

### Adicionado
- `install.sh`: isolamento de dados do adb via `ANDROID_SDK_HOME="$HOME/.termux-adb"` (evita clutter no `$HOME` do Termux, ideia inspirada no MasterDevX/Termux-ADB, implementada via env var oficial do adb)
- `wireless-adb.sh`: helper interativo para pareamento/conexão ADB wireless (Android 11+), sem precisar de cabo/OTG
- `uninstall.sh`: agora também limpa `ANDROID_SDK_HOME` do `.bashrc`/`.zshrc` e remove `~/.termux-adb`
- `NOTICE.md`: atribuição explícita aos projetos que inspiraram cada melhoria
- `README.md`: reescrito como projeto independente, com tabela de créditos e seção "como funciona"

### Alterado
- `LICENSE`: copyright ajustado para refletir autoria destes scripts (MIT mantida)

## [1.0.0] - 2026-08-06

Base inicial via apt repo do nohajc/termux-adb (MIT).

### Testado
- `termux-adb --version` → Android Debug Bridge 1.0.41, 35.0.2-android-tools
- `termux-fastboot --version` → 35.0.2-android-tools
- Repo apt validado com gpg (`nohajc.gpg`), pacote `termux-adb` instalável via `pkg`
- Daemon `adb` sobe corretamente (`termux-adb devices`)
- `termux-usb -l` funcional (dependente de device físico conectado via OTG)

### Adicionado
- `install.sh`: `set -e`, checagem de arquitetura, auto-instalação de `termux-api`
- `uninstall.sh`: remove pacote, repo list e gpg key
- `README.md`: seção de uninstall
- `CHANGELOG.md`: este arquivo

### Removido
- Submodule `android-tools` e `.github/` (não necessários para instalação/uso end-user)
