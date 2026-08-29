# Depuração do próprio aparelho (localhost)

É possível conectar o ADB ao **próprio aparelho** (`127.0.0.1`), sem qualquer cabo.
Esse procedimento é útil para:

- Conceder permissões a aplicativos como Brevent, Ice Box e Shizuku;
- Abrir um shell ADB local (`adb shell`);
- Usar o scrcpy para espelhamento em um dispositivo remoto.

## Pré-requisitos

- Android 11 ou superior;
- Depuração wireless ativada (veja [USO_WIRELESS.md](USO_WIRELESS.md)).

## Procedimento assistido

```bash
adblocalhost
```

O script solicita a **porta de pareamento** (`Pair device with pairing code`) e o
**código de 6 dígitos**; em seguida, a **porta de conexão** (`IP address & Port`,
diferente da de pareamento).

## Procedimento manual

```bash
adb pair 127.0.0.1:PORT_PAREAMENTO   # informar o código de 6 dígitos
adb connect 127.0.0.1:PORT_CONEXAO
adb devices
```

O pareamento é único; nas conexões seguintes basta `adb connect`.

## Observações

- Recomenda-se usar **split-screen** para manter o diálogo de pareamento visível
  enquanto o código é digitado no Termux.
- A sessão ADB depende do daemon ativo: se a depuração wireless for desligada, a
  conexão cai.