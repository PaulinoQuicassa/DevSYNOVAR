# Estado do Projeto — Fila Certa

_Última atualização: 2026-08-22_

## Estado atual

Protótipo Flutter funcional e interativo, cliente-only (sem backend). Fluxo completo de entrada em fila e de agendamento implementado e navegável, sem botões "mortos". `flutter analyze` limpo, testes automatizados a passar, `flutter build web --release` a compilar sem erros.

## Funcionalidades

- [x] Home com CTA "Entrar numa fila" e localizações próximas (tocar num cartão vai direto ao serviço desse local)
- [x] Escolher localização — pesquisa real (filtra por nome/agência/morada), filtro "próximos de si" (≤5 km) vs "todas", estado vazio quando não há resultados
- [x] Escolher serviço — pesquisa real por nome/descrição
- [x] Ecrã "A sua senha" — número, progresso da fila, balcão, confirmação antes de sair da fila, folha de contacto real (telefone/WhatsApp/email do banco)
- [x] Ecrã "Está quase" — alerta, WhatsApp real (`wa.me`), interruptor de alertas com estado próprio, folha de "detalhes da fila", confirmação antes de sair
- [x] Ecrã "É a sua vez" — chamada, hora real, direções reais via Google Maps, confirmação antes de "não posso comparecer"
- [x] Avaliação do atendimento — estrelas, recomendação, comentário, aspetos específicos; ao submeter, cria uma entrada real no histórico ("Os meus atendimentos")
- [x] **Novo agendamento** (fluxo completo): escolher local → escolher serviço → escolher data (14 dias) e hora → confirmar → ecrã de confirmação com **QR code real** e código único
- [x] Agendamentos — lista ligada a estado real (`appointmentsStore`); cada cartão abre um detalhe com QR e opção de cancelar (com confirmação)
- [x] Os meus atendimentos — lista ligada a estado real (`historyStore`); cada cartão abre um detalhe com a avaliação dada
- [x] Perfil — todas as opções ligadas: Notificações (interruptores reais), Definições (idioma + repor dados de demonstração), Ajuda e suporte (FAQ + contacto real), Sobre a Fila Certa, Terminar sessão (com confirmação)
- [x] Navegação inferior persistente durante todo o fluxo (fila e agendamento, cada um com o separador certo destacado)

## Em desenvolvimento

Nada em curso neste momento.

## Problemas conhecidos

- Nenhum bug funcional conhecido.
- Sem persistência entre execuções da app — agendamentos/histórico/notificações voltam ao estado inicial ao reiniciar (é um protótipo sem backend; há um botão em Definições para repor os dados de demonstração manualmente durante uma demo).
- Sem modo escuro — decisão deliberada, ver `CLAUDE.md` ("O que NÃO alterar sem confirmação").
- Ilustrações fotorrealistas das imagens de referência foram simplificadas para composições de ícones (limitação de geração de imagem, não um bug).
- Logótipos dos bancos são monogramas coloridos, não a arte real das marcas (decisão deliberada, para não reproduzir logótipos registados).
- Ações de `url_launcher` (chamar, WhatsApp, email, mapas) não puderam ser testadas em dispositivo real nesta sessão (sem emulador/telemóvel ligado) — só validadas por compilação e revisão de código.

## Testes

| Comando | Resultado |
|---|---|
| `flutter analyze` | PASS — 0 problemas |
| `flutter test` | PASS — 2/2 (smoke test + fluxo completo de agendamento) |
| `flutter build web --release` | PASS |

## Arquitetura

Ver `CLAUDE.md` para detalhes de stack, estrutura e convenções. Resumo: sem gestor de estado externo, sem backend, dados mock + estado mutável em memória (`app_stores.dart`), navegação via `Navigator` + `FlowScaffold`, ações reais do dispositivo via `url_launcher`, QR real via `qr_flutter`.

## Últimas alterações

- Passagem completa de "torna a app funcional": eliminados todos os botões sem ação (`onTap: () {}`), criado o fluxo de "Novo agendamento" de ponta a ponta (com QR code real), criadas 8 telas novas (agendamento, detalhes de agendamento/atendimento, notificações, definições, ajuda, sobre), pesquisa e filtros passaram a filtrar de verdade, ações de contacto/mapas/WhatsApp abrem apps reais via `url_launcher`.
- Corrigidos 4 bugs reais de overflow de layout (`RenderFlex overflowed`) descobertos pelo novo teste end-to-end — texto longo sem `Flexible`/`ellipsis` em `GradientButton`, `LocationSummaryCard`, `ServiceCard` e no cartão de agendamento.
- Renomeação completa de "FilaJá" para "Fila Certa" em todos os aspectos (tarefa anterior).
- Projeto organizado com Claude Code: `git init`, `CLAUDE.md` (raiz), `.claude/agents/flutter.md`, este ficheiro (tarefa anterior).

## Próximos passos (sugestões, não decisões tomadas)

- Decidir se este protótipo vai ganhar backend real e persistência, ou continuar como demo com dados mock em memória.
- Testar as ações `url_launcher` (chamar, WhatsApp, mapas) num dispositivo/emulador real.
- Ecrãs de atendente/supervisor/painel TV existem apenas como conceito visual noutro artefacto — decidir se entram neste repositório Flutter.
