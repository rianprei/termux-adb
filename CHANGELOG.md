# Changelog

## [4.0.0] - 2026-08-29

### Adicionado
- Front-end unificado `adb` com roteamento automático do backend (termux-adb para OTG via termux-usb; adb nativo para wireless)
- Watcher OTG (`adb-otg-watcher`) mantém cache de detecção em segundo plano (decisão de roteamento em ~1 ms)
- Front-end `fastboot` encaminhando para `termux-fastboot`
- Ferramentas: `adbs` (diagnóstico), `adbw` (wireless guiado), `adbmenu` (interface de menu), `adbpair`, `adbotg`, `adblocalhost`
- Integração com scrcpy (espelhamento) e ADBash (shell Bash na sessão ADB)
- Documentação estruturada em `docs/` (instalação, OTG, wireless, localhost, troubleshooting, segurança)
- README reescrito com tabela de comparação ampliada e badges

### Alterado
- Substituídos os symlinks `adb`→`termux-adb` por front-ends em `$HOME/.local/bin` com roteamento automático
- `termux-adb-update` passa a atualizar todos os scripts e front-ends
- `termux-adb-doctor` passa a checar os front-ends e o watcher

## [3.2.0] - 2026-08-06

### Corrigido
- `README.md`: descricao corrigida — "self-contained" em vez de "repo apt mantido"
- `README.md`: tabela comparativa — "Auto-updates" em vez de "Updates via apt"
- `termux-adb-doctor.sh`: checa dpkg + GitHub Releases em vez de apt repo/GPG key (falsos positivos eliminados)
- `termux-adb-doctor.sh`: adiciona check de symlinks adb/fastboot e termux-adb-update
- `uninstall.sh`: remove `apt-get update` desnecessario (nao usamos mais apt)

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

## v4.1.0 (2026-09-15) — wireless sem atrito (termux-adb-research §12.5)

- **magisk-module/** (termuxadb_rootport v1.0, testado ao vivo no lake 2x): porta fixa 5555 no boot (post-fs-data), setprop → fallback resetprop, log em /data/local/tmp/termuxadb_rootport.log. Zero interação, sobrevive a reboot.
- **`adbw --watch [IP] [PORTA]`**: reconexão automática com backoff 3s→30s, estado em ~/.cache/adbw-state; detecta o módulo Magisk via getprop e usa a porta fixa 5555 automaticamente.
- **`adbw-root-porta [porta]`** (root, sem módulo): mesma técnica on-demand via su.
- **`adbw-sweep <IP> [--dry]`** (sem root): descoberta de porta dinâmica via nmap 32768-60999 — substitui `adb mdns`, ausente no android-tools do Termux (build nmeum: MDNS=OFF).
- **`adb-keys-backup`**: backup/restore tar.gz das chaves RSA de host (~/.termux-adb), perms 600/644.
- **doctor**: novos checks — módulo Magisk (instalado? prop ativa?), phantom process killer, mDNS ausente (esperado), chaves de host.
- test/test-watch.sh: suite host-side do --watch com stubs (6 checks).
