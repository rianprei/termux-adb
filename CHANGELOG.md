# Changelog

## [3.1.0] - 2026-08-06

### Adicionado
- `install.sh`: symlinks `adb` → `termux-adb` e `fastboot` → `termux-fastboot` (digita só `adb`)
- `termux-adb-update.sh`: NOVO — auto-updater que checa e atualiza scripts + pacote
- `install.sh`: instala `termux-adb-update` no PATH
- `uninstall.sh`: remove symlinks `adb`/`fastboot` e `termux-adb-update`
- Crédito ao offici5l pelo conceito de symlinks e auto-updater

## [3.0.0] - 2026-08-06

### Adicionado
- `install.sh`: verificação SHA256 da GPG key antes de confiar (previne MITM)
- `install.sh`: fallback com mensagem clara se repo upstream estiver offline
- `install.sh`: arch check agora bloqueia (`exit 1`) em vez de só avisar
- `install.sh`: health-check pós-install (roda `termux-adb version` e confirma)
- `install.sh`: instala `wireless-adb` e `termux-adb-doctor` no PATH automaticamente
- `install.sh`: output com cores (verde/vermelho/amarelo/azul) pra UX clara
- `uninstall.sh`: remove `wireless-adb` e `termux-adb-doctor` do PATH
- `uninstall.sh`: health-check reverso (confirma que termux-adb saiu do PATH)
- `wireless-adb.sh`: detecta IP local automaticamente via `ip route`
- `wireless-adb.sh`: valida formato IP:porta antes de tentar conectar
- `wireless-adb.sh`: timeout de 15s em pair e connect
- `termux-adb-doctor.sh`: NOVO — diagnóstico completo (binários, termux-api, repo, config, extras)
- `CONTRIBUTING.md`: NOVO — guia de contribuição
- `.gitignore`: NOVO

### Alterado
- `install.sh`: binários agora baixados do nosso próprio repo (GitHub Releases), não depende mais do apt repo do nohajc
- `install.sh`: instalação via `dpkg -i` direto do .deb, não via apt repo externo
- `ANDROID_SDK_HOME` → `ANDROID_USER_HOME` (ambos setados por compatibilidade)
- `uninstall.sh`: limpa ambas as variáveis dos shell RCs
- `README.md`: reescrito com tabela comparativa, seções doctor/wireless/desinstalar
- Projeto 100% self-contained — pode cair qualquer servidor externo que o nosso continua funcionando

## [2.0.0] - 2026-08-06

### Adicionado
- `install.sh`: isolamento de dados do adb via `ANDROID_SDK_HOME`
- `wireless-adb.sh`: helper interativo para ADB wireless (Android 11+)
- `NOTICE.md`: atribuição explícita aos projetos inspiradores

## [1.0.0] - 2026-08-06

### Testado
- `termux-adb --version` → Android Debug Bridge 1.0.41, 35.0.2-android-tools
- `termux-fastboot --version` → 35.0.2-android-tools
- Repo apt validado, daemon adb funcional, `termux-usb -l` funcional

### Adicionado
- `install.sh`: `set -e`, checagem de arquitetura, auto-instalação de `termux-api`
- `uninstall.sh`: remove pacote, repo list e GPG key
