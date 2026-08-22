# Estado do Projeto — Fila Certa

_Última atualização: 2026-08-22_ · Repositório: [github.com/PaulinoQuicassa/DevSYNOVAR](https://github.com/PaulinoQuicassa/DevSYNOVAR) (privado) · Testado em Android real pelo utilizador (build + instalação confirmadas a funcionar).

## Estado atual

Protótipo Flutter funcional e interativo, agora **com backend real** (Firebase Auth + Firestore): contas de utilizador com email e palavra-passe, agendamentos/histórico/preferências ligados à conta e sincronizados entre dispositivos. Fluxo completo de entrada em fila e de agendamento implementado e navegável, sem botões "mortos". Ligado a um projeto Firebase real do utilizador (`filacerta-d74f0`) — `lib/firebase_options.dart` já não é placeholder. `flutter analyze` limpo, todos os testes automatizados a passar, `flutter build web --release` e `flutter build apk --debug` a compilar sem erros com a configuração real.

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
- [x] Perfil — todas as opções ligadas: Notificações (interruptores reais, sincronizados), Definições (idioma sincronizado + limpar todos os dados da conta), Ajuda e suporte (FAQ + contacto real), Sobre a Fila Certa, Terminar sessão real (com confirmação, `authService.signOut()`)
- [x] Navegação inferior persistente durante todo o fluxo (fila e agendamento, cada um com o separador certo destacado)
- [x] **Contas de utilizador reais e sincronização entre dispositivos** (Firebase Auth + Firestore) — entrar/criar conta com email e palavra-passe (`LoginScreen`/`SignupScreen`), recuperação de palavra-passe; agendamentos, histórico e preferências (notificações, idioma) ligados à conta (`users/{uid}/...`), não ao aparelho, protegidos por `firestore.rules`

## Em desenvolvimento

Nada em curso neste momento.

## Problemas conhecidos

- Nenhum bug funcional conhecido.
- Sem modo escuro — decisão deliberada, ver `CLAUDE.md` ("O que NÃO alterar sem confirmação").
- Ilustrações fotorrealistas das imagens de referência foram simplificadas para composições de ícones (limitação de geração de imagem, não um bug).
- Logótipos dos bancos são monogramas coloridos, não a arte real das marcas (decisão deliberada, para não reproduzir logótipos registados).
- Ações de `url_launcher` (chamar, WhatsApp, email, mapas) ainda não foram testadas manualmente num dispositivo real (só validadas por compilação e revisão de código).

## Testes

| Comando | Resultado |
|---|---|
| `flutter analyze` | PASS — 0 problemas |
| `flutter test` | PASS — 4/4 (`widget_test.dart`: smoke test, agendamento ponta a ponta, catálogo SIAC, navegação completa por todos os ecrãs — cada um autenticado com `MockFirebaseAuth`/`FakeFirebaseFirestore`) |
| `flutter build web --release` | PASS (com Firebase real) |
| `flutter build apk --debug` | PASS (com Firebase real) |

## Arquitetura

Ver `CLAUDE.md` para detalhes de stack, estrutura e convenções. Resumo: sem gestor de estado externo, backend real (Firebase Auth + Cloud Firestore), dados de localizações/serviços mock + estado de conta (agendamentos/histórico/preferências) em `app_stores.dart` sincronizado em tempo real via Firestore, navegação via `Navigator` + `FlowScaffold`, ações reais do dispositivo via `url_launcher`, QR real via `qr_flutter`.

## Últimas alterações

- **Ligação ao Firebase real concluída**: o utilizador criou o projeto `filacerta-d74f0` no consola Firebase, ativou Email/Password, criou o Firestore e publicou `firestore.rules`; depois instalámos `firebase-tools`+`flutterfire_cli` e corremos `firebase login`+`flutterfire configure`, que gerou `lib/firebase_options.dart` real (Android/iOS/macOS/web/Windows) e `android/app/google-services.json`, e aplicou o plugin Gradle do Google Services. `flutter build apk --debug` e `flutter build web --release` confirmados a compilar com a configuração real.
- **Backend real adicionado**: Firebase Auth (email+palavra-passe) e Cloud Firestore substituem a persistência local (`shared_preferences`, removida). Novo `lib/auth/auth_service.dart`, ecrãs `AuthGate`/`LoginScreen`/`SignupScreen`, e `app_stores.dart` reescrito para sincronizar cada store (`appointmentsStore`, `historyStore`, `notificationSettings`, `appLanguageController`) com `users/{uid}/...` no Firestore em tempo real. `firestore.rules` criado (cada conta só acede aos seus próprios documentos). Perfil mostra o email real da conta e tem terminar sessão real. Definições ganhou "Limpar todos os dados" (apaga da conta em todos os dispositivos) em vez de "Repor dados de demonstração". Testes reescritos com `firebase_auth_mocks`+`fake_cloud_firestore`, incluindo a correção de uma armadilha real do `firebase_auth_mocks` (o seu `authStateChanges()` não repete o estado já autenticado a um listener tardio — `AuthGate` agora semeia a partir de `authService.currentUser`).
- **(Anterior) Persistência local real** adicionada (`shared_preferences`, entretanto removida): agendamentos, histórico, notificações e idioma sobreviviam a fechar a app. `main()` carregava tudo (`hydrateAllStores()`) antes do primeiro `runApp`.
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

- Instalar o `app-debug.apk` recém-compilado num Android real e testar o fluxo completo de conta (criar conta, entrar, agendar, terminar sessão, entrar noutro aparelho e confirmar que os dados aparecem).
- Confirmar no consola Firebase que as regras publicadas em `firestore.rules` correspondem exatamente ao ficheiro do repositório (foram publicadas manualmente antes de o ficheiro existir na versão atual — vale a pena confirmar).
- Testar as ações `url_launcher` (chamar, WhatsApp, mapas) num dispositivo/emulador real.
- Ecrãs de atendente/supervisor/painel TV existem apenas como conceito visual noutro artefacto — decidir se entram neste repositório Flutter.
- Sincronização atual cobre só os dados pessoais da conta (agendamentos/histórico/preferências) — filas ao vivo partilhadas entre utilizadores diferentes (lado do atendente/balcão) ficou fora de escopo desta tarefa, por decisão explícita do utilizador.
