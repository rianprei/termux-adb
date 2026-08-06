# Changelog

## [1.0.0] - 2026-08-06

Fork de [nohajc/termux-adb](https://github.com/nohajc/termux-adb) (MIT).

### Testado
- `termux-adb --version` → Android Debug Bridge 1.0.41, 35.0.2-android-tools
- `termux-fastboot --version` → 35.0.2-android-tools
- Repo apt validado com gpg (`nohajc.gpg`), pacote `termux-adb` instalável via `pkg`
- Daemon `adb` sobe corretamente (`termux-adb devices`)
- `termux-usb -l` funcional (dependente de device físico conectado via OTG)

### Adicionado
- `install.sh`: `set -e` — script para no primeiro erro em vez de seguir e imprimir "done!" mesmo em falha
- `install.sh`: checagem de arquitetura (`uname -m`) contra lista suportada, com aviso se desconhecida
- `install.sh`: checagem e auto-instalação de `termux-api` (dependência real do `termux-usb`, antes não verificada)
- `uninstall.sh`: remove pacote, repo list e gpg key — não existia antes
- `README.md`: seção de uninstall
- `CHANGELOG.md`: este arquivo

### Removido
- Submodule `android-tools` (fonte do build, não necessário para instalação/uso end-user)
- `.github/` (workflows específicos do fork original, não aplicáveis aqui)
