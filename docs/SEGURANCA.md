# Segurança

Boas práticas ao operar ADB no Termux.

## Acessos concedidos

- **Wireless ADB** expõe um serviço ADB na sua rede local. Qualquer aparelho na mesma
  rede com a chave RSA correspondente pode tentar conectar. Use apenas em redes
  privadas e de confiança.
- **termux-usb** concede acesso a dispositivos USB conectados; o popup de permissão é
  o seu controle. Revogue acessos não utilizados por intermédio das permissões do app.

## Recomendações

1. **Desative a depuração wireless** quando não estiver em uso no aparelho alvo.
2. **Remova pares não utilizados** em `Depuração wireless > Parear dispositivo`.
3. **`adb kill-server`** antes de sair de uma rede compartilhada.
4. Não execute pareamentos em redes públicas.
5. Os binários `.deb` são publicados com **verificação SHA256** no `install.sh`.
   Verifique o hash antes de qualquer instalação manual de novos pacotes.
6. Mantenha os dados ADB isolados no diretório `~/.termux-adb` (configuração padrão
   deste projeto), longe de scripts compartilhados.

## Modelo de ameaças resumido

| Ameaça | Mitigação |
|--------|-----------|
| Conexão ADB não autorizada na LAN | Usar apenas redes privadas; desligar wireless ADB quando não usado. |
| Acesso USB indevido | Conceder permissão (`termux-usb`) apenas a dispositivos conhecidos. |
| Pacote adulterado | Verificação SHA256 + download exclusivo pelo GitHub Releases oficial. |
| Dados de ADB (chaves RSA) vazando | Isolamento em `~/.termux-adb` com permissões restritas. |

Em caso de dúvida, desative o serviço e utilize `adb kill-server`.