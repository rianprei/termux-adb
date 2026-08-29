# Solução de problemas

Guia de referência para os erros mais comuns.

## `ERROR IN RESULTRETURNER` (Termux:API)

**Causa:** o app Android **Termux:API** (`com.termux.api`) não responde corretamente.
Isso costuma acontecer quando o app é instalado pela **Play Store** (versão
desatualizada/incompatível) ou quando a versão do pacote `termux-api` do Termux diverge
da versão do app.

**Verificação:**
```bash
termux-usb -l          # deve retornar [] ou uma lista JSON
termux-battery-status  # deve retornar um JSON com dados
```

**Correção:**
```bash
pkg reinstall termux-api
```
- **Desinstale** o Termux:API instalado pela Play Store;
- **Instale** a versão do [F-Droid](https://f-droid.org/packages/com.termux.api/).

Após reinstalar, reinicie o Termux e teste novamente `termux-usb -l`.

## `no devices/emulators found`

- Verifique se a **depuração USB/wireless** está ativa no aparelho alvo;
- Confirme o cabeamento OTG/cabo;
- Execute:
  ```bash
  adb kill-server && adb start-server
  adb devices
  ```

## Dispositivo parece `offline`

- O aparelho alvo não aceitou o prompt RSA de autorização. Replugue, aceite o prompt e
  repita.
- No modo wireless, execute `adb kill-server` e reconecte.

## `failed to connect` / `connection refused` (wireless)

- A porta utilizada está errada; consulte a tela de "Depuração wireless" (a porta de
  conectção difere da de pareamento e muda a cada reinício).
- Mesma rede Wi-Fi obrigatória (sem isolamento de cliente).
- Reative o toggle de depuração wireless se a porta estiver em uso.

## `error: protocol fault (couldn't read status message)`

- Reinicie a depuração wireless no aparelho alvo;
- Como fallback, conecte via USB e execute `adb tcpip 5555`, depois `adb connect`.

## Código de pareamento inválido

Gere um novo código no menu "Pair device with pairing code" do aparelho alvo e repita
o pareamento.

## Pareamento com timeout

- Use **split-screen** para manter o diálogo de pareamento visível enquanto digita o
  código;
- Verifique o formato `IP:PORTA` (sem protocolo `http://`).

## `termux-adb` não encontrado no PATH

Reexecute o instalador:
```bash
curl -s https://raw.githubusercontent.com/rianprei/termux-adb/main/install.sh | bash
```
Ou consulte o [doctor](INSTALACAO.md): `termux-adb-doctor`.

## Fastboot muito lento

A enumeração de serial via `termux-usb`/libusb é lenta por construção. O `adb` reduz
o impacto por rodar como daemon; o `fastboot` não tem daemon, então cada comando sofre
o atraso. Seja paciente ou planeje os timeouts.

## Permissões do app Termux:API

Comandos que acessam SMS, localização, contatos etc. exigem permissões no Android.
Conceda-as em `Ajustes > Aplicativos > Termux:API > Permissões`.