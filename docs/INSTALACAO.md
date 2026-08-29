# Instalação

Guia detalhado de instalação do Termux ADB Unificado.

## Requisitos

- **Termux** — instale pelo [F-Droid](https://f-droid.org/packages/com.termux/).
  **Não** utilize a versão da Play Store (desatualizada e incompatível com este projeto).
- **Termux:API** — instale pelo [F-Droid](https://f-droid.org/packages/com.termux.api/).
  Disponibiliza o utilitário `termux-usb`, essencial para o acesso USB OTG sem root.
- **Espaço em disco** — cerca de 100 MB livres para binários e dependências.

> Para o modo OTG, e necessário um aparelho com suporte a USB host. Para usar apenas
> via wireless, é suficiente um aparelho com Android 11+.

## Instalação em um comando

```bash
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/install.sh | bash
```

O instalador executa as etapas a seguir, em ordem:

1. **Verificação de arquitetura** — aceita `aarch64` e `arm` (armv7l/armv8l); bloqueia as demais.
2. **Dependências base** — instala `wget`.
3. **termux-api** — instala o pacote automaticamente se `termux-usb` não estiver presente.
4. **Download e instalação do pacote `.deb`** — obtido do GitHub Releases do projeto, com
   **verificação SHA256** antes da instalação via `dpkg`. O processo é interrompido no
   primeiro erro (`set -e`).
5. **Isolamento de dados** — define `ANDROID_USER_HOME` e `ANDROID_SDK_HOME` apontando
   para `~/.termux-adb` nos arquivos `.bashrc` e `.zshrc`.
6. **Ferramentas extras** — `wireless-adb`, `termux-adb-doctor`, `termux-adb-update`,
   `adbotg`, `adbpair`, `adbw`, `adblocalhost`, `adbs` e `adbmenu` instaladas em
   `$PREFIX/bin`.
7. **Front-ends unificados** — `adb`, `fastboot` e `adb-otg-watcher` instalados em
   `~/.local/bin`, que antecede `$PREFIX/bin` no `PATH`.
8. **Health-check** — executa `termux-adb version` e `termux-fastboot --version` para
   confirmar que tudo está funcional.

## Verificar a instalação

```bash
adb version
adb devices
adbs
```

O `adbs` consolida o diagnóstico: versões dos backends, estado do `termux-usb`,
variáveis de ambiente e a lista de dispositivos.

## Atualização

```bash
termux-adb-update
```

Consulta a release mais recente do GitHub, atualiza scripts e front-ends e, havendo
nova versão do pacote no `install.sh`, reinstala automaticamente.

## Desinstalação

```bash
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/uninstall.sh | bash
```

Remove o pacote, ferramentas extras, front-ends, watcher, as linhas de configuração
dos shell RCs e o diretório isolado `~/.termux-adb`.

## Solução de problemas

Consulte [TROUBLESHOOTING.md](TROUBLESHOOTING.md) para os erros mais comuns, incluindo o
erro `ERROR IN RESULTRETURNER` do Termux:API.