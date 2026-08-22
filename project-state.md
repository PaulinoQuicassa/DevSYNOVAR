# Estado do Projeto — Fila Certa

_Última atualização: 2026-08-22_ · Repositório: [github.com/PaulinoQuicassa/DevSYNOVAR](https://github.com/PaulinoQuicassa/DevSYNOVAR) (privado) · Testado em Android real pelo utilizador (build + instalação confirmadas a funcionar).

## Estado atual

Protótipo Flutter funcional e interativo, cliente-only (sem backend). Fluxo completo de entrada em fila e de agendamento implementado e navegável, sem botões "mortos", **com persistência local real** (sobrevive a fechar a app). `flutter analyze` limpo, todos os testes automatizados a passar, `flutter build web --release` e `flutter build apk --debug` a compilar sem erros.

## Funcionalidades

- [x] Home com CTA "Entrar numa fila" e localizações próximas (tocar num cartão vai direto ao serviço desse local)
- [x] Escolher localização — pesquisa real (filtra por nome/agência/morada), filtro "próximos de si" (≤5 km) vs "todas", estado vazio quando não há resultados
- [x] Escolher serviço — pesquisa real por nome/descrição; **cada localização tem o seu próprio catálogo de serviços** (bancos: atendimento/depósitos/cartões/crédito; SIAC: catálogo real com 13 serviços — BI, Registo Civil, Trânsito/DTSER, Passaporte/SME, Cartório Notarial, Registo Automóvel, Registo Comercial, Registo Predial, NIF/AGT, INSS, Ficheiro Central, CAEC, Administração Distrital)
- [x] Ecrã "A sua senha" — número, progresso da fila, balcão, confirmação antes de sair da fila, folha de contacto real (telefone/WhatsApp/email do banco)
- [x] Ecrã "Está quase" — alerta, WhatsApp real (`wa.me`), interruptor de alertas com estado próprio, folha de "detalhes da fila", confirmação antes de sair
- [x] Ecrã "É a sua vez" — chamada, hora real, direções reais via Google Maps, confirmação antes de "não posso comparecer"
- [x] Avaliação do atendimento — estrelas, recomendação, comentário, aspetos específicos; ao submeter, cria uma entrada real no histórico ("Os meus atendimentos") **e persiste**
- [x] **Novo agendamento** (fluxo completo): escolher local → escolher serviço → escolher data (14 dias) e hora → confirmar → ecrã de confirmação com **QR code real** e código único — **persiste**
- [x] Agendamentos — lista ligada a estado real (`appointmentsStore`, persistido); cada cartão abre um detalhe com QR e opção de cancelar (com confirmação)
- [x] Os meus atendimentos — lista ligada a estado real (`historyStore`, persistido); cada cartão abre um detalhe com a avaliação dada
- [x] Perfil — todas as opções ligadas: Notificações (interruptores reais, persistidos), Definições (idioma persistido + repor dados de demonstração), Ajuda e suporte (FAQ + contacto real), Sobre a Fila Certa, Terminar sessão (com confirmação)
- [x] Navegação inferior persistente durante todo o fluxo (fila e agendamento, cada um com o separador certo destacado)
- [x] **Persistência local em disco** (`shared_preferences`) — agendamentos, histórico, preferências de notificação e idioma sobrevivem a fechar e reabrir a app no mesmo aparelho

## Em desenvolvimento

Nada em curso neste momento.

## Problemas conhecidos

- Nenhum bug funcional conhecido.
- Persistência é só local ao dispositivo — sem conta/login, não sincroniza entre aparelhos (não há backend).
- Sem modo escuro — decisão deliberada, ver `CLAUDE.md` ("O que NÃO alterar sem confirmação").
- Ilustrações fotorrealistas das imagens de referência foram simplificadas para composições de ícones (limitação de geração de imagem, não um bug).
- Logótipos dos bancos são monogramas coloridos, não a arte real das marcas (decisão deliberada, para não reproduzir logótipos registados).
- Ações de `url_launcher` (chamar, WhatsApp, email, mapas) ainda não foram testadas manualmente num dispositivo real (só validadas por compilação e revisão de código).

## Testes

| Comando | Resultado |
|---|---|
| `flutter analyze` | PASS — 0 problemas |
| `flutter test` | PASS — 10/10 (`widget_test.dart`: smoke test, agendamento ponta a ponta, catálogo SIAC, navegação completa por todos os ecrãs; `persistence_test.dart`: 6 testes de gravação/leitura) |
| `flutter build web --release` | PASS |
| `flutter build apk --debug` | PASS — instalado e testado em Android real pelo utilizador |

## Arquitetura

Ver `CLAUDE.md` para detalhes de stack, estrutura e convenções. Resumo: sem gestor de estado externo, sem backend, dados mock + estado em `app_stores.dart` persistido localmente via `persistence.dart` (`shared_preferences`), navegação via `Navigator` + `FlowScaffold`, ações reais do dispositivo via `url_launcher`, QR real via `qr_flutter`.

## Últimas alterações

- **Persistência local real** adicionada (`shared_preferences`): agendamentos, histórico, notificações e idioma sobrevivem a fechar a app. `Appointment` grava-se como referência (`locationMonogram`+`serviceName`) resolvida contra `MockData` ao carregar; `Visit` grava-se como retrato histórico (campos soltos), com a cor sempre recalculada a partir do `monogram` atual em vez de gravada. `main()` carrega tudo (`hydrateAllStores()`) antes do primeiro `runApp`. Atualizado o aviso em Definições, que já não dizia a verdade.
- Corrigida uma inconsistência de dados: o histórico mock do SIAC ainda tinha o nome antigo ("SIAC — Centro de Atendimento") e um serviço genérico, desatualizados desde a mudança para o catálogo real do SIAC.
- Adicionado um teste de "navegação completa" que visita todos os ecrãs alcançáveis a partir das abas e do Perfil — encontrou e permitiu corrigir mais 3 bugs reais: aviso de `Material`/`ListTile` invisível na Ajuda (FAQ), overflow no ecrã Sobre, overflow na pílula "Tempo estimado" do ecrã da fila.
- Cartões de serviço tornados mais compactos (menos padding, ícones menores, altura fixa por `mainAxisExtent` em vez de `childAspectRatio`) — já não sobra espaço vazio em baixo. A correção revelou (e resolveu) mais 2 bugs de overflow (`status_pill.dart`, cabeçalho da Home); todos os testes passaram a usar 390px (largura realista de telemóvel) em vez da largura de teste por defeito.
- `QueueLocation` passou a ter o seu próprio catálogo de serviços (`services`) em vez de todas as localizações partilharem a mesma lista genérica de banco. O SIAC recebeu um catálogo real de 13 serviços, com dados fornecidos pelo utilizador sobre o portal oficial do SIAC.
- Repositório Git ligado ao GitHub (`PaulinoQuicassa/DevSYNOVAR`, privado) — todo o histórico local enviado.
- Confirmado a funcionar em Android real (o utilizador instalou e testou o `app-debug.apk` num dispositivo/emulador ligado, depois de instalar o Android SDK e o JDK).
- Passagem completa de "torna a app funcional": eliminados todos os botões sem ação, criado o fluxo de "Novo agendamento" de ponta a ponta (com QR code real), criadas 8 telas novas, pesquisa e filtros a filtrar de verdade, ações de contacto/mapas/WhatsApp a abrir apps reais via `url_launcher`.
- Renomeação completa de "FilaJá" para "Fila Certa" em todos os aspectos (tarefa anterior).
- Projeto organizado com Claude Code: `git init`, `CLAUDE.md` (raiz), `.claude/agents/flutter.md`, este ficheiro (tarefa anterior).

## Próximos passos (sugestões, não decisões tomadas)

- Testar as ações `url_launcher` (chamar, WhatsApp, mapas) num dispositivo/emulador real.
- Decidir se este protótipo vai ganhar um backend real (contas de utilizador, sincronização entre dispositivos, filas ao vivo) ou continuar como demo local.
- Ecrãs de atendente/supervisor/painel TV existem apenas como conceito visual noutro artefacto — decidir se entram neste repositório Flutter.
