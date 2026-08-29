# Contribuindo

Issues e pull requests são bem-vindos.

## Reportar um problema

Abra uma issue com:

- Output de `termux-adb-doctor` (diagnóstico completo);
- Arquitetura (`uname -m`);
- Versão do Termux (`apt list --installed 2>/dev/null | grep termux-tools`);
- Passos para reproduzir, se aplicável.

## Enviar um pull request

- Teste no Termux real antes de abrir o PR;
- Mantenha `set -e` em todos os scripts;
- Atualize o `CHANGELOG.md`;
- Atualize a documentação em `docs/` se o comportamento público mudar;
- Mantenha a compatibilidade com `aarch64` e `arm`.

## Licença

Ao contribuir, você concorda que suas contribuições serão licenciadas sob MIT.