# Estado do Projeto — Fila Certa

_Última atualização: 2026-08-21_

## Estado atual

Protótipo Flutter funcional, cliente-only (sem backend). Fluxo completo de entrada em fila implementado e navegável, com dados mock. `flutter analyze` limpo, único teste automatizado a passar.

## Funcionalidades

- [x] Home com CTA "Entrar numa fila" e localizações próximas
- [x] Escolher localização (pesquisa, filtro "próximos de si", lista de bancos mock)
- [x] Escolher serviço (grid de serviços por localização)
- [x] Ecrã "A sua senha" (número, progresso da fila, balcão)
- [x] Ecrã "Está quase" (alerta, WhatsApp, alertas)
- [x] Ecrã "É a sua vez" (chamada, detalhes do atendimento)
- [x] Avaliação do atendimento (estrelas, recomendação, comentário, aspetos específicos)
- [x] Separadores "Os meus atendimentos", "Agendamentos", "Perfil" (conteúdo mock)
- [x] Navegação inferior de 5 itens persistente durante todo o fluxo

## Em desenvolvimento

Nada em curso neste momento — protótipo do fluxo do cliente está completo face às referências em `Imagensdeecrans/`.

## Problemas conhecidos

- Nenhum bug funcional conhecido.
- Ilustrações fotorrealistas das imagens de referência foram simplificadas para composições de ícones (limitação de geração de imagem, não um bug).
- Logótipos dos bancos são monogramas coloridos, não a arte real das marcas (decisão deliberada, para não reproduzir logótipos registados).

## Testes

| Comando | Resultado |
|---|---|
| `flutter analyze` | PASS — 0 problemas |
| `flutter test` | PASS — 1/1 |
| `flutter build web --release` | PASS |

## Arquitetura

Ver `CLAUDE.md` para detalhes de stack, estrutura e convenções. Resumo: sem gestor de estado externo, sem backend, dados mock, navegação via `Navigator` + `FlowScaffold`.

## Últimas alterações

- Renomeação completa de "FilaJá" para "Fila Certa" em todos os aspectos: pacote Dart (`fila_certa_app`), `applicationId`/`namespace` Android, bundle id iOS/macOS, nomes de produto Windows/Linux, classes Dart (`FilaCertaApp`, `FilaCertaBottomNav`), e todo o texto visível.
- Projeto organizado com Claude Code: `git init`, `CLAUDE.md` (raiz), `.claude/agents/flutter.md`, este ficheiro.
- Correção de aviso de lint (`justify-content` inválido não se aplica aqui — nota: essa correção foi no design system HTML separado, não neste código Flutter).

## Próximos passos (sugestões, não decisões tomadas)

- Decidir se este protótipo vai ganhar backend real ou continuar como demo com dados mock.
- Ecrãs de atendente/supervisor/painel TV existem apenas como conceito visual noutro artefacto — decidir se entram neste repositório Flutter.
