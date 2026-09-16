# Termux ADB Unificado

ADB e Fastboot no Termux **sem root** e **sem desbloquear o bootloader**.

[![versão-4.0.0](https://img.shields.io/badge/vers%C3%A3o-4.0.0-blue)](https://github.com/rianprei/termux-adb/releases/tag/v4.0.0)
[![licença-MIT](https://img.shields.io/badge/licen%C3%A7a-MIT-green)](LICENSE)

Este projeto integra as principais implementações do ecossistema ADB do Termux — USB OTG via `termux-usb`, wireless (Android 11+), localhost e espelhamento via scrcpy — em uma **interface de comando única** com roteamento automático de backend.

## Recursos principais

- **USB OTG sem root (dispositivo→dispositivo)** — binário `termux-adb` patchado, acesso via `termux-usb`.
- **Wireless (Android 11+, pareamento por código)** — front-end `adb` + assistente interativo `adbw`.
- **Localhost (depuração do próprio aparelho)** — `adblocalhost` (conexão em `127.0.0.1`).
- **Front-end unificado `adb`** — decide automaticamente entre `termux-adb` (OTG) e o `adb` nativo (wireless), com decisão baseada em cache do watcher (latência de ~1 ms).
- **Fastboot sem root** — front-end `fastboot` encaminha para `termux-fastboot`.
- **Diagnóstico integrado** — `adbs` (status rápido) e `termux-adb-doctor` (verificação completa).
- **Menu interativo** — `adbmenu`, consolidando todas as operações.
- **Espelhamento de tela com scrcpy** — opcional, integrado ao menu e ao diagnóstico.
- **Config isolada** — dados do ADB em `~/.termux-adb`, fora do `$HOME`.
- **Distribuição própria** — binários `.deb` hospedados no GitHub Releases, com verificação de integridade SHA256.

## Requisitos

- **Termux** e **Termux:API** — ambos do [F-Droid](https://f-droid.org/). **Não** utilizar as versões da Play Store (são desatualizadas e incompatíveis).
- **Dispositivo Android com suporte a USB host** — para a modalidade OTG. Alternativamente, **Android 11+** para usar via wireless sem cabo.
- **~100 MB de armazenamento livre** para o conjunto de binários e dependências.

## Instalação

Instale Termux e Termux:API pelo F-Droid e execute:

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/install.sh | bash
```

O instalador executa as seguintes etapas, nesta ordem:

1. **Verificação de arquitetura** — bloqueia arquiteturas não suportadas (suportadas: `aarch64`, `arm`/`armv7l`/`armv8l`).
2. **Dependências base** — instala `wget`.
3. **termux-api** — instala automaticamente se `termux-usb` não estiver presente.
4. **Download e instalação do pacote `.deb`** (GitHub Releases) com **verificação SHA256** antes da instalação via `dpkg`; o processo para no primeiro erro (`set -e`).
5. **Isolamento de dados** — define `ANDROID_USER_HOME` e `ANDROID_SDK_HOME` apontando para `~/.termux-adb` nos shell RCs (`.bashrc`/`.zshrc`).
6. **Ferramentas extras** — instaladas no PATH (`$PREFIX/bin`).
7. **Front-ends unificados** — `adb`, `fastboot` e `adb-otg-watcher` em `~/.local/bin`, com garantia de precedência no PATH.
8. **Health-check** — executa `termux-adb version` e `termux-fastboot --version` para confirmar a instalação.

O projeto é 100% self-contained: os binários são hospedados no próprio repositório, sem dependência de servidores externos.

## Uso

### USB OTG (cabo)

```
adb devices
```

Na primeira vez, o dispositivo Android solicita permissão USB — aceite. Para listar e conceder permissão aos dispositivos OTG conectados, use `adbotg`.

### Wireless (Android 11+, sem cabo)

```
adbw
```

O `adbw` é um guia interativo: detecta o IP local, valida os endereços `IP:PORTA`, executa o pareamento por código e a conexão, com timeout de 15 s por etapa. Alternativamente, faça manualmente:

```
adb pair IP:PORTA_PAREAMENTO CODIGO
adb connect IP:PORTA
```

### Pareamento rápido

```
adbpair IP:PORTA_PAREAMENTO CODIGO [IP:PORTA_CONEXAO]
```

Se a porta de conexão não for informada, apenas o pareamento é executado.

### Localhost (próprio aparelho)

```
adblocalhost
```

Conecta em `127.0.0.1` via depuração wireless, permitindo depurar o próprio dispositivo.

### Diagnóstico

```
adbs
termux-adb-doctor
```

`adbs` consolida o status geral do ambiente: backends, modos de acesso e aplicação de configuração. `termux-adb-doctor` realiza a verificação completa (binários, termux-api, pacote dpkg, configuração isolada, front-ends e ferramentas extras) com saída verde/vermelha por item.

### Menu interativo

```
adbmenu
```

Reúne as operações mais comuns: conexão wireless e localhost, listagem OTG, `adb shell`, espelhamento via scrcpy, shell Bash na sessão ADB (`ADBash.sh`), instalação de APK, `pull`/`push`, diagnóstico e pareamento.

### Status do ambiente

```
adbs
```

Exibe versões de backend, estado do `termux-usb`, variáveis de ambiente e a lista de dispositivos (`adb devices`).

## Ferramentas instaladas

| Comando               | Destino           | Função |
|-----------------------|-------------------|--------|
| `termux-adb`          | `$PREFIX/bin`     | Binário ADB patchado (OTG via `termux-usb`), instalado via `dpkg`. |
| `termux-fastboot`     | `$PREFIX/bin`     | Binário Fastboot patchado, instalado via `dpkg`. |
| `adb`                 | `~/.local/bin`    | Front-end unificado com roteamento automático de backend. |
| `fastboot`            | `~/.local/bin`    | Front-end que encaminha para `termux-fastboot`. |
| `adb-otg-watcher`     | `~/.local/bin`    | Watcher de background que mantém o cache OTG atualizado. |
| `wireless-adb`        | `$PREFIX/bin`     | Assistente interativo de conexão wireless (usa `termux-adb`). |
| `adbotg`              | `$PREFIX/bin`     | Lista dispositivos USB OTG via `termux-usb -l`. |
| `adbpair`             | `$PREFIX/bin`     | Pareamento rápido por código. |
| `adbw`                | `$PREFIX/bin`     | Conexão wireless interativa; `adbw --watch [IP] [PORTA]` mantém a sessão viva com reconexão automática. |
| `adbw-root-porta`     | `$PREFIX/bin`     | Porta fixa de ADB via root (persist.adb.tcp.port, default 5555). |
| `adbw-sweep`          | `$PREFIX/bin`     | Descoberta de porta dinâmica sem root via nmap (32768-60999). |
| `adb-keys-backup`     | `$PREFIX/bin`     | Backup/restore das chaves RSA de host (~/.termux-adb). |
| `adblocalhost`        | `$PREFIX/bin`     | Depuração do próprio aparelho (`127.0.0.1`). |
| `adbs`                | `$PREFIX/bin`     | Status geral do sistema ADB (diagnóstico rápido). |
| `adbmenu`             | `$PREFIX/bin`     | Menu interativo das ferramentas ADB. |
| `termux-adb-doctor`   | `$PREFIX/bin`     | Diagnóstico completo do ambiente. |
| `termux-adb-update`   | `$PREFIX/bin`     | Auto-updater de scripts e pacote. |

## Modo root: módulo Magisk

O módulo **`magisk-module/`** (id `termuxadb_rootport`) resolve de vez o principal atrito do wireless debugging em Android 11+: **a porta de conexão TLS aleatória que muda a cada boot e o toggle que se desliga sozinho**.

### O que ele faz

No boot (gancho `post-fs-data`, antes do Android terminar de subir), o módulo grava `persist.adb.tcp.port=5555`:

- **`setprop` direto** — caminho oficial AOSP (o adbd lê `persist.adb.tcp.port` com fallback para `service.adb.tcp.port`, `daemon/main.cpp:275-277`);
- **fallback automático `resetprop`** do Magisk se o SELinux negar o setprop (comportamento esperado em builds novos — ver `docs/SEGURANCA.md` e `context/termux-adb-research.md` §10.1);
- log de execução em `/data/local/tmp/termuxadb_rootport.log`.

Resultado: **ADB escutando fixo na porta 5555, sempre ligado, zero interação manual, sobrevive a reboot** (testado ao vivo no lake/POCO C75, HyperOS). Não existe mais porta aleatória pra descobrir — o `adbw --watch` passa a tentar sempre `IP:5555` primeiro.

### Instalação

Via adb/terminal:

```bash
adb push magisk-module /data/local/tmp/termuxadb_rootport
su -c "magisk --install-module /data/local/tmp/termuxadb_rootport"
```

Ou pelo app Magisk: **Módulos → Install from storage** → selecione o zip do módulo (empacote a pasta `magisk-module/`). Reboot necessário para o gancho `post-fs-data` rodar.

### Verificação

```bash
getprop persist.adb.tcp.port          # deve retornar 5555
adb connect <IP-do-aparelho>:5555     # de qualquer host da rede
```

Ou rode `termux-adb-doctor` — ele detecta o módulo instalado.

### Aviso

A porta fixa 5555 é **plaintext + autenticação RSA** (não é o TLS do wireless A11+). Use somente em rede confiável — ver `docs/SEGURANCA.md`.

## Como funciona

O `termux-adb` utiliza a API `termux-usb` do Termux:API para obter file descriptors de dispositivos USB sem exigir root. Os binários são patchados em `lib` para remapear `/dev/bus/usb` para um diretório virtual, e um **Unix Domain Socket (UDS)** transfere os descriptors entre processos — o que permite múltiplos dispositivos conectados, inclusive via hub USB no OTG.

O front-end `adb` une as duas famílias de acesso:

- **OTG** → `termux-adb` (patch nohajc via `termux-usb`);
- **Wireless/localhost** → `adb` nativo (android-tools, mais rápido).

O `adb-otg-watcher` consulta `termux-usb -l` em background (instância única garantida por `flock`, atualização a cada 4 s) e grava o resultado em `~/.termux-adb/otg.cache`. O front-end decide a rota com apenas um `stat` + um `cat` (~1 ms), sem bloquear. O comando `pair`/`connect`/`disconnect` e demais operações de rede são direcionados sempre ao backend nativo. O pacote `dpkg` fornece os binários `termux-adb` e `termux-fastboot`; o roteamento para os front-ends `adb`/`fastboot` em `~/.local/bin` garante a interface unificada.

## Comparação

| Feature | nohajc | MasterDevX | rendiix | **Este (v4.0.0)** |
|---------|:------:|:----------:|:-------:|:------------------:|
| Sem root | ✅ | ❌ | ❌ | ✅ |
| OTG via termux-usb | ✅ | ❌ | ❌ | ✅ |
| Wireless ADB | ❌ | ❌ | ❌ | ✅ |
| Localhost ADB | ❌ | ❌ | ❌ | ✅ |
| Diagnóstico | ❌ | ❌ | ❌ | ✅ |
| Uninstall limpo | ❌ | ✅ | ❌ | ✅ |
| Config isolada | ❌ | ✅ | ❌ | ✅ |
| Auto-updater | ❌ | ❌ | ❌ | ✅ |
| Verificação SHA256 | ❌ | ❌ | ❌ | ✅ |
| Arquitetura check | ❌ | ❌ | ❌ | ✅ |
| Front-end com roteamento automático | ❌ | ❌ | ❌ | ✅ |
| Watcher / baixa latência | ❌ | ❌ | ❌ | ✅ |
| scrcpy integrado | ❌ | ❌ | ❌ | ✅ |
| Menu interativo | ❌ | ❌ | ❌ | ✅ |
| Distribuição própria | ❌ | ❌ | ❌ | ✅ |

## Atualização

```
termux-adb-update
```

Consulta a release mais recente no GitHub, atualiza os scripts instalados e, se houver nova versão do pacote no `install.sh`, reinstala-o automaticamente. Os front-ends `adb`/`fastboot` e o watcher são atualizados ao final.

## Desinstalação

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/uninstall.sh | bash
```

Remove o pacote, ferramentas extras, front-ends e watcher, as linhas de configuração dos shell RCs e o diretório isolado `~/.termux-adb`.

## Limitações

A **enumeração do serial** via `libusb`/`termux-usb` é lenta. No `adb`, o impacto é mitigado pelo daemon, que varre periodicamente os dispositivos; já o `fastboot`, por não possuir daemon em background, torna a operação perceptivelmente lenta. Leve os timeouts em consideração ao operar no modo fastboot.

O `adb` do Termux **conectando nele mesmo** (mesmo aparelho, via IP da LAN ou `127.0.0.1`) fica preso em `unauthorized` — o diálogo de autorização RSA nunca aparece na tela e o `logcat` não mostra nenhum evento de `AdbDebuggingManager`/RSA sendo processado. Confirmado em testes reais (LAN e loopback, com reautenticação forçada via `kill-server`) num device Android 16/HyperOS: o `adbd` no modo clássico `tcpip` (porta fixa, não a TLS de "Depuração sem fio") simplesmente não dispara esse fluxo pra conexões que se originam do próprio aparelho. Não é bug do `adbw` — o script reporta a falha de transporte corretamente. Afeta só o caso self-connect; conectar a partir de outro host (PC, outro celular) funciona normalmente e mostra o prompt.

## Créditos

Projeto que reúne e consolida as ideias do ecossistema ADB do Termux:

- **[nohajc/termux-adb](https://github.com/nohajc/termux-adb)** — patch do adb/fastboot + integração `termux-usb` (sem root).
- **[MasterDevX/Termux-ADB](https://github.com/MasterDevX/Termux-ADB)** — conceito de isolamento dos dados do adb fora do `$HOME`.
- **[rendiix/termux-adb-fastboot](https://github.com/rendiix/termux-adb-fastboot)** — validação do padrão de distribuição.
- **[offici5l/termux-adb-fastboot](https://github.com/offici5l/termux-adb-fastboot)** — conceito dos symlinks `adb → termux-adb` e do auto-updater.

Scripts, documentação e a infraestrutura de instalação são originais deste projeto. Consulte [NOTICE.md](NOTICE.md) para a atribuição detalhada dos binários redistribuídos.

## Licença

Distribuído sob a licença [MIT](LICENSE).
