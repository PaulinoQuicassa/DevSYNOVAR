# Fila Certa

Protótipo Flutter de uma plataforma de gestão inteligente de filas e atendimento (mercado angolano). App cliente com fluxo completo de entrada em fila, agendamento, acompanhamento e avaliação, usando dados mock — sem backend/API/DB/auth. Agendamentos, histórico e preferências persistem **localmente no dispositivo** (não há sincronização entre dispositivos, nem servidor).

## Stack

- Flutter 3.47.1 · Dart >=3.3.0 · Material 3
- Dependências: `google_fonts`, `cupertino_icons`, `url_launcher` (chamar, WhatsApp, email, mapas — abre apps reais do dispositivo), `qr_flutter` (QR code real e legível nos agendamentos), `shared_preferences` (persistência local)
- Sem backend/API/DB/auth — dados mock em `lib/data/mock_data.dart`, estado mutável em `lib/app_stores.dart`, persistido em disco por `lib/persistence.dart`

## Estrutura

```
lib/
├── main.dart              # entry point — hydrateAllStores() corre ANTES do runApp
├── app_state.dart         # rootTabController — navegação global entre separadores
├── app_stores.dart        # AppointmentsStore, HistoryStore, NotificationSettings,
│                           #  appLanguageController — estado em memória, espelhado em disco
├── persistence.dart       # save/load de cada store via SharedPreferences (JSON)
├── theme/app_theme.dart   # cores e tipografia (AppColors, AppTheme)
├── models/                # QueueLocation, ServiceItem, Appointment, Visit
├── data/mock_data.dart    # dados mock (bancos, serviços, senhas, contactos de suporte)
├── screens/                # ~20 ecrãs — ver lista abaixo
└── widgets/                # componentes reutilizáveis (cards, botões, nav bar,
                             #  confirm_dialog, contact_sheet)
```

- `Imagensdeecrans/` — mockups de referência (gerados fora do projeto) que guiaram o design "FilaJá"/"Fila Certa".
- `scripts/serve_web.js` — servidor estático simples para pré-visualizar `flutter build web` localmente.
- Cada `QueueLocation` tem o seu próprio `services: List<ServiceItem>` — os bancos (BPC/BFA/BAI/BCI) partilham `MockData.bankServices`; o SIAC usa `MockData.siacServices`, um catálogo real (Bilhete de Identidade, Registo Civil, Trânsito/DTSER, Passaporte/SME, Cartório Notarial, Registo Automóvel, Registo Comercial, Registo Predial, NIF/AGT, INSS, Ficheiro Central, CAEC, Administração Distrital). Ao adicionar uma localização nova, nunca reaproveitar `bankServices` para um tipo de balcão diferente — criar (ou escolher) a lista de serviços certa para esse tipo de entidade.

### Persistência

`Appointment`/`Visit` guardam-se como JSON simples (não os objetos completos): um `Appointment` grava `locationMonogram`+`serviceName` e resolve-os de volta contra `MockData` ao carregar (se a localização/serviço já não existir no catálogo atual, esse registo é ignorado em silêncio, não crasha o arranque). Um `Visit` já era um "retrato" histórico com campos soltos (`bank`, `monogram`, `service` como texto), por isso persiste quase tal e qual — só a `color` é sempre recalculada a partir do `monogram` atual em `MockData` em vez de ser gravada, para nunca ficar dessincronizada se a marca de um banco mudar de cor no futuro. Cada store novo com estado mutável global deve seguir este padrão: `hydrate()` assíncrono chamado uma vez a partir de `hydrateAllStores()` (em `main.dart`, antes do `runApp`), e persistir depois de cada mutação (`add`/`cancel`/`reset`/`toggle`, via `unawaited(Persistence.save...())`).

### Ecrãs

Fluxo do cliente: Home → ChooseLocation → ChooseService → Queue → Almost → Called → Rating.
Fluxo de agendamento (reutiliza ChooseLocation/ChooseService com `isScheduling: true`): ChooseLocation → ChooseService → ScheduleDateTime → AppointmentConfirmed → AppointmentDetail (a partir da lista em Agendamentos).
Separadores: Home, MyAppointments (histórico, alimentado por `historyStore`), Schedule (agendamentos, alimentado por `appointmentsStore`), Profile.
A partir do Perfil: NotificationSettings, Settings (idioma + repor dados de demonstração), Help (FAQ + contacto), About, VisitDetail (a partir do histórico).

## Convenções observadas

- Sem gestor de estado externo (Provider/Riverpod/Bloc) — estado local via `setState`, estado partilhado via `ValueNotifier`/`ChangeNotifier` globais em `app_state.dart`/`app_stores.dart` (padrão consistente, não introduzir outro).
- Cada widget/ecrã tem construtor `const` sempre que os campos o permitem.
- Design tokens centralizados em `AppColors`/`AppTheme` (`lib/theme/app_theme.dart`) — evitar cores/hex soltos nos ecrãs.
- Navegação da fila e do agendamento usa `Navigator.push` normal (root navigator), mantendo a barra inferior via `FlowScaffold` (aceita `currentIndex` — 2 para a fila, 3 para agendamento) em cada ecrã do fluxo.
- Texto/label num `Row` que pode crescer (nomes, datas formatadas, labels dinâmicos) deve ir dentro de `Flexible`/`Expanded` com `overflow: TextOverflow.ellipsis` — já houve overflow real em ecrãs estreitos por esquecer isto (ver `GradientButton`, `LocationSummaryCard`, `ServiceCard`, `StatusPill`, `AboutScreen`, cabeçalho da Home, pílula "Tempo estimado" da fila).
- Um `ExpansionTile`/`ListTile` dentro de um cartão precisa de estar num `Material` (com `shape`+`clipBehavior: Clip.antiAlias` para manter cantos arredondados e contorno), nunca só num `Container` com `BoxDecoration` colorido — caso contrário o ripple/fundo do `ListTile` fica invisível (aviso real do framework, ver `HelpScreen`).
- Ações que alteram estado do utilizador (sair da fila, cancelar agendamento, não comparecer, terminar sessão) pedem confirmação via `confirmAction` (`lib/widgets/confirm_dialog.dart`) antes de executar.
- Contacto com bancos/suporte usa `showContactSheet`/`openMapsDirections` (`lib/widgets/contact_sheet.dart`), que abrem apps reais via `url_launcher` — não simular com `SnackBar`.

## Comandos

```bash
flutter pub get      # instalar dependências
flutter analyze      # lint/type-check — deve devolver "No issues found!"
flutter test         # correr testes (todas as suites)
flutter run          # correr num dispositivo/emulador
flutter build web    # build de produção para browser
```

## Testes

- `test/widget_test.dart`:
  1. Smoke test: a Home renderiza e o botão "Entrar numa fila" navega para "Escolher localização".
  2. Fluxo completo de agendamento, ponta a ponta (local/serviço/data/hora → confirmar → código+QR → aparece em Agendamentos).
  3. O SIAC mostra o seu catálogo real de serviços, não a lista de bancos.
  4. **Navegação completa**: visita todos os ecrãs alcançáveis a partir das abas e do Perfil, numa largura realista de telemóvel — é o teste que apanha overflows escondidos; ao adicionar um ecrã novo, acrescentar aqui a visita a esse ecrã.
- `test/persistence_test.dart` — testa `lib/persistence.dart` isoladamente (save/load de cada store, incluindo o caso "lista vazia gravada" vs "nunca gravado").
- Os testes usam `SharedPreferences.setMockInitialValues({})` no `setUp()` — os métodos das stores (`add`/`reset`/`toggle`) disparam gravação real mesmo em teste, e sem isto falhariam à procura de uma plataforma que não existe no ambiente de teste.
- Os testes usam `appointmentsStore.reset()`/`historyStore.reset()` em `setUp()` para começarem sempre do mesmo estado — qualquer novo `ValueNotifier`/`ChangeNotifier` global mutável deve seguir o mesmo padrão (método `reset()` + reset no `setUp` do teste, e um teste de persistência dedicado).
- **Os testes usam sempre `tester.view.physicalSize` com uma largura realista de telemóvel (390px), nunca a largura de teste por defeito (~800px)** — a largura por defeito esconde overflows que só aparecem num telemóvel real.
- Para telas por onde um botão possa ficar perto do fundo de um `ListView` longo, preferir um viewport de teste **alto** (`tester.view.physicalSize = const Size(390, h_grande)`) em vez de `tester.ensureVisible()` — este último pode acertar noutra camada da interface (chrome do `Scaffold`) em vez do widget alvo.
- Para fechar um ecrã aberto com `ScreenHeader`, usar `tester.tap(find.byIcon(Icons.arrow_back))` — `tester.pageBack()` não reconhece este botão próprio (não é um `BackButton`/`AppBar` standard do Flutter).

## O que NÃO alterar sem confirmação

- Dados mock em `lib/data/mock_data.dart` — refletem os mockups originais em `Imagensdeecrans/`; alterações de conteúdo devem ser deliberadas, não incidentais.
- Não foi implementado modo escuro deliberadamente: `AppColors` são constantes estáticas referenciadas diretamente em todos os ecrãs (não vêm de `Theme.of(context)`), por isso um toggle de tema não teria efeito visual real sem reescrever todos os ecrãs — não adicionar um toggle "fake" no Settings sem fazer essa reescrita primeiro.

## Histórico de nomenclatura

O projeto chamou-se inicialmente "FilaJá"; a marca foi depois alterada para "Fila Certa" em todos os aspectos — identificador do pacote Dart (`fila_certa_app`), `applicationId`/`namespace` Android (`com.example.fila_certa_app`), bundle id iOS/macOS (`com.example.filaCertaApp`), nomes de produto Windows/Linux, classes Dart (`FilaCertaApp`, `FilaCertaBottomNav`) e todo o texto visível. Não deve restar nenhuma referência a "filaja"/"FilaJá" no código — se encontrares alguma, é um resíduo a corrigir.

## Estado atual

Protótipo funcional e interativo, **com persistência local real** — agendamentos, histórico e preferências (idioma, notificações) sobrevivem a fechar e reabrir a app no mesmo dispositivo (sem sincronizar entre dispositivos, sem servidor). Todos os ecrãs do fluxo do cliente e de agendamento estão implementados e ligados (sem botões "mortos"). Ações de contacto (telefone, WhatsApp, email, mapas) abrem apps reais do dispositivo via `url_launcher`. Não existem ainda os lados de atendente/supervisor/painel TV (esses existem apenas como conceito visual noutro artefacto, fora deste repositório Flutter).
