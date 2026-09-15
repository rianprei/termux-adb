# termux-adb: Porta Fixa Root (módulo Magisk)

Fixa `persist.adb.tcp.port` em `5555` automaticamente a cada boot, via root, sem
depender do toggle "Depuração wireless" nem da porta TLS aleatória que o Android
11+ sorteia a cada reinício (`TlsServer(0)`, código do adbd — ver
[`context/termux-adb-research.md`](../../tabs-agent-os/context/termux-adb-research.md)
para a pesquisa completa com fonte AOSP linha a linha).

## Por que módulo Magisk, não script

Um script Termux exige abrir o Termux e rodar manualmente depois de cada boot.
Um módulo Magisk roda `post-fs-data.sh` **antes do Android terminar de
inicializar** — zero interação, sempre ativo, mesmo que o Termux nunca seja
aberto. Mesmo princípio de arquitetura do [Sui](https://github.com/RikkaApps/Sui)
(módulo Magisk irmão do Shizuku): sem binário solto, sem passo manual, integra
como parte do boot.

## Instalação

**Via Magisk app:**
1. Baixe o `.zip` da [release](../../releases) mais recente deste módulo.
2. Magisk → Módulos → Instalar do armazenamento → selecione o zip.
3. Reinicie.

**Via linha de comando (root):**
```
adb push termuxadb-rootport.zip /sdcard/
adb shell su -c "magisk --install-module /sdcard/termuxadb-rootport.zip"
adb reboot
```

## Verificação

Depois do reboot:
```
adb shell getprop persist.adb.tcp.port
# esperado: 5555

adb shell su -c "cat /data/local/tmp/termuxadb_rootport.log"
# esperado: linha "OK: persist.adb.tcp.port=5555" com timestamp do boot
```

Conecte direto, sem pareamento, sem descobrir porta:
```
adb connect <ip-do-aparelho>:5555
```

## Como funciona (`post-fs-data.sh`)

1. `setprop persist.adb.tcp.port 5555` — caminho oficial AOSP
   (`daemon/main.cpp`, módulo adb: lê `persist.adb.tcp.port` com fallback pra
   `service.adb.tcp.port`, faz listen em `tcp:<port>`).
2. Se a prop não pegar (builds recentes com SELinux mais restritivo negam
   `setprop` direto em `persist.adb.*` mesmo pra domínio root — achado
   documentado em relatos de campo, r/AndroidRoot 2024-2025), cai pro fallback
   `resetprop` do próprio Magisk, que escreve a prop por fora do
   `property_service` padrão.
3. Log em `/data/local/tmp/termuxadb_rootport.log` — timestamp de cada boot,
   resultado (OK ou qual caminho falhou), sem silêncio.

## Segurança

Porta 5555 fica em modo **plaintext + autenticação RSA por chave** (não é o
modo TLS do "Depuração wireless" da UI — é o modo clássico do `adb tcpip`,
só que permanente). Use apenas em rede local confiável; qualquer host na
mesma LAN que tenha (ou consiga que você aceite) uma chave RSA autorizada
pode conectar. Recomendado: desligar o Wi-Fi do aparelho fora de casa, ou
remover o módulo quando não precisar mais do acesso permanente.

## Testado

Instalado e verificado ao vivo (device rooted via Magisk, Android 16/HyperOS):
reboot real, log confirmando execução automática no boot, porta 5555 fixa
confirmada via `getprop` após o reboot — sem intervenção manual.
