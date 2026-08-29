# Uso via USB OTG

O Termux ADB Unificado permite depurar um aparelho Android a partir do próprio
Termux, conectando dois dispositivos por cabo, **sem root**.

## Como funciona

O pacote `termux-adb` entrega binários de `adb`/`fastboot` patchados que não acessam
`/dev/bus/usb` diretamente (o que exigiria root). Em vez disso, eles usam o utilitário
`termux-usb` do app [Termux:API](https://f-droid.org/packages/com.termux.api/), que:

1. Enumera os dispositivos USB disponíveis (`termux-usb -l`);
2. Obtém permissão do usuário para acessar o dispositivo (`termux-usb -r` ou auto no
   primeiro uso);
3. Fornece um file descriptor do dispositivo, transferido entre processos via
   **Unix Domain Socket (UDS)**.

Um hook em `lib` remapeia `/dev/bus/usb` para um diretório virtual, permitindo que o
`adb` liste dispositivos `aarch64` sem nenhuma permissão especial.

## Hardware necessário

- **Cabo USB-C macho-macho** (dois aparelhos USB-C), ou
- **Adaptador OTG** + cabo normal (para micro-USB).

Para múltiplos aparelhos simultâneos, é possível usar um **hub USB** no modo OTG.

## Primeiro uso

```bash
adbotg        # lista dispositivos USB via termux-usb -l
adb devices   # o aparelho solicita permissão USB — aceite
```

Na primeira conexão o Android exibe o diálogo de autorização USB. A permissão pode
expirar a cada reconexão ou reinício do Termux — é esperado que o diálogo reapareça.

## Operações comuns

```bash
adb shell                             # shell remoto
adb push arquivo-local /sdcard/       # enviar arquivo
adb pull /sdcard/arquivo .            # baixar arquivo
adb install app.apk                   # instalar aplicativo
termux-fastboot flash recovery twrp.img
termux-fastboot reboot                # em modo bootloader
```

Para usar um aparelho específico (com hub):

```bash
adb -s <serial> shell
```

## Dicas

- O `adb` do front-end unificado detecta automaticamente o modo OTG e encaminha para
  `termux-adb`; com transporte wireless ele usa o backend nativo.
- O `adb devices` pode demorar a exibir o dispositivo na primeira vez porque o
  `termux-usb` agrega a descoberta em background.

## Problemas comuns

| Problema | Solução |
|----------|---------|
| Dispositivo não aparece em `adb devices` | Confirme que a depuração USB está ativa no aparelho alvo; troque o cabo/porta; verifique `termux-usb -l`. |
| Popup de permissão não aparece | Replugue o cabo; verifique se o app Termux:API está instalado e atualizado. |
| `no devices/emulators found` | Execute `adb kill-server && adb start-server` e tente novamente. |
| Fastboot demorado | A enumeração via `termux-usb` é lenta; o fastboot não possui daemon em background. Aguarde ou aumente o timeout. |