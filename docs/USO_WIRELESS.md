# Uso via Wireless (Android 11+)

O modo wireless exige **Android 11 (API 30) ou superior**. Permite conectar o Termux a
outro aparelho (ou ao próprio) na mesma rede **sem cabo e sem root**.

## Pré-requisitos no aparelho alvo

1. Ative **Opções do desenvolvedor**: `Ajustes > Sobre o telefone`, toque 7 vezes em
   "Número da versão".
2. Em `Opções do desenvolvedor`, ative **Depuração USB** e, em seguida,
   **Depuração wireless**.
3. Em "Depuração wireless" você verá duas informações distintas:
   - **IP address & Port** — porta de conexão (listada em *Connected devices*);
   - **Pair device with pairing code** — porta de pareamento (diferente) + código de
     6 dígitos.

> **Importante:** a porta de pareamento e a porta de conexão são diferentes. Além
> disso, a porta de conexão **muda a cada reinicialização** do aparelho, enquanto o
> pareamento é realizado apenas uma vez.

## Conexão assistida (recomendada)

```bash
adbw
```

O `adbw` guia o processo: detecta o IP local, valida `IP:PORTA`, executa o pareamento
(se necessário) e a conexão, com timeout de 15 s por etapa.

## Conexão manual

```bash
adb pair 192.168.1.100:37123       # porta de PAREAMENTO + código solicitado
adb connect 192.168.1.100:5555     # porta de CONEXÃO (different do pareamento)
adb devices                        # confirma o dispositivo
```

Para reagrupamento rápido, se a porta de conexão for conhecida:

```bash
adbpair 192.168.1.100:37123 123456 192.168.1.100:5555
```

## Após reiniciar o aparelho alvo

A porta de conexão muda. Reexecute apenas:

```bash
adb connect 192.168.1.100:NOVA_PORTA
```

## Dicas

- Conecte apenas na **mesma rede Wi-Fi**; o wireless ADB geralmente não funciona em
  redes com isolamento de cliente ou em dados móveis.
- Mantenha o diálogo de pareamento com **split-screen** ao lado do Termux, pois o
  diálogo fecha ao perder o foco.
- Se o dispositivo aparecer como `offline`, execute `adb kill-server` e conecte
  novamente.
- Para Android < 11, use o método clássico com cabo: conecte via USB, execute
  `adb tcpip 5555` e, após desconectar, `adb connect IP:5555`.

## Solução de problemas

| Erro | Solução |
|------|---------|
| `failed to connect` / connection refused | Porta errada ou depuração wireless desativada; reinicie o toggle de "Depuração wireless" e refaça. |
| `error: protocol fault` | Reinicie a depuração wireless no aparelho alvo; confirme que ambos estão na mesma rede. |
| Código inválido | Gere um novo código no menu de pareamento e repita. |
| Dispositivo `offline` | `adb kill-server` e nova conexão. |