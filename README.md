# termux-adb

ADB e Fastboot no Termux **sem root**. Repo apt mantido, config isolada, verificação de integridade, wireless mode, diagnóstico integrado, uninstall limpo.

## Instalação

Instale [Termux](https://f-droid.org/packages/com.termux/) e [Termux:API](https://f-droid.org/packages/com.termux.api/) pelo F-Droid, depois:

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/install.sh | bash
```

O installer:
- Bloqueia arquiteturas não suportadas
- Instala `termux-api` automaticamente se faltar
- Verifica integridade do .deb (SHA256) antes de instalar
- Instala `termux-adb` e `termux-fastboot` via dpkg direto do nosso repo
- Cria symlinks `adb` → `termux-adb` e `fastboot` → `termux-fastboot` (digita só `adb`)
- Isola dados do adb em `~/.termux-adb` (não suja seu `$HOME`)
- Instala `wireless-adb`, `termux-adb-doctor` e `termux-adb-update` no PATH
- Roda health-check no final e confirma que tudo funciona
- Para no primeiro erro (`set -e`)

**100% self-contained** — binários hospedados no nosso repo (GitHub Releases), não depende de nenhum servidor externo.

## Uso

### USB (cabo OTG)

```
adb devices
```

Na primeira vez o Android pede permissão USB — aceite.

### Wireless (Android 11+, sem cabo)

```
wireless-adb
```

Guia interativo: detecta seu IP, valida endereços, timeout de 15s em cada passo.

### Diagnóstico

```
termux-adb-doctor
```

Verifica tudo: binários, termux-api, app Termux:API, repo apt, GPG key, config, ferramentas extras. Output verde/vermelho por item.

### Atualizar

```
termux-adb-update
```

Verifica se há nova versão, atualiza scripts e pacote automaticamente.

## Desinstalar

```
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/uninstall.sh | bash
```

Remove tudo: pacote, symlinks, ferramentas extras, config isolada, variáveis de ambiente dos shell RCs.

## Como funciona

O `termux-adb` usa a API `termux-usb` do Termux:API para obter file descriptors de dispositivos USB sem precisar de root. Os binários adb/fastboot são patchados para varrer dispositivos via `termux-usb` em vez de acessar `/dev/bus/usb` diretamente. Um Unix Domain Socket transfere os descriptors entre processos — funciona com múltiplos dispositivos (ex: hub USB no OTG).

## Comparação

| Feature | nohajc | MasterDevX | rendiix | **Este** |
|---------|--------|-----------|---------|----------|
| Sem root | ✅ | ❌ | ❌ | ✅ |
| Updates via apt | ✅ | ❌ | ✅ | ✅ |
| Uninstall limpo | ❌ | ✅ | ❌ | ✅ |
| Config isolada | ❌ | ✅ | ❌ | ✅ |
| Wireless ADB | ❌ | ❌ | ❌ | ✅ |
| Diagnóstico (doctor) | ❌ | ❌ | ❌ | ✅ |
| Auto-install termux-api | ❌ | ❌ | ❌ | ✅ |
| Verificação de arquitetura | ❌ | ❌ | ❌ | ✅ |
| Health-check pós-install | ❌ | ❌ | ❌ | ✅ |
| SHA256 verify | ❌ | ❌ | ❌ | ✅ |
| Fail-fast (set -e) | ❌ | ❌ | ❌ | ✅ |
| Self-contained (sem deps externas) | ❌ | ✅ | ❌ | ✅ |
| Symlinks adb/fastboot | ❌ | ❌ | ❌ | ✅ |
| Auto-updater | ❌ | ❌ | ❌ | ✅ |

## Limitações

Consultar serial via `libusb`/`termux-usb` é lento. Não afeta adb (daemon, varre periodicamente), mas é perceptível no fastboot (sem serviço em background).

## Créditos

Projeto independente que reúne as melhores ideias do ecossistema:

- **[nohajc/termux-adb](https://github.com/nohajc/termux-adb)** — patch adb/fastboot + `termux-usb` sem root, distribuído via apt repo próprio
- **[MasterDevX/Termux-ADB](https://github.com/MasterDevX/Termux-ADB)** — conceito de isolamento de dados do adb fora do `$HOME`
- **[rendiix/termux-adb-fastboot](https://github.com/rendiix/termux-adb-fastboot)** — validou padrão de distribuição via apt repo + GPG key
- **[offici5l/termux-adb-fastboot](https://github.com/offici5l/termux-adb-fastboot)** — symlinks `adb`→`termux-adb` e conceito de auto-updater

Ver [NOTICE.md](NOTICE.md) para detalhes de atribuição.

## Licença

[MIT](LICENSE)
