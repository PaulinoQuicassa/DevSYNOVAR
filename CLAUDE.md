# Fila Certa

Protótipo Flutter de uma plataforma de gestão inteligente de filas e atendimento (mercado angolano). App cliente com fluxo completo de entrada em fila, agendamento, acompanhamento e avaliação, usando dados mock para localizações/serviços, mas com **contas de utilizador reais e sincronização entre dispositivos** via Firebase (Auth + Firestore).

## Stack

- Flutter 3.47.1 · Dart >=3.3.0 · Material 3
- Dependências: `google_fonts`, `cupertino_icons`, `url_launcher` (chamar, WhatsApp, email, mapas — abre apps reais do dispositivo), `qr_flutter` (QR code real e legível nos agendamentos), `firebase_core`, `firebase_auth` (email+palavra-passe), `cloud_firestore`
- Dados de localizações/serviços continuam mock (`lib/data/mock_data.dart`) — não fazem parte da conta do utilizador. Os dados da conta (agendamentos, histórico, preferências) são reais e vivem no Firestore, sob `users/{uid}/...`, protegidos por `firestore.rules` (só o dono da conta lê/escreve os seus documentos).

## Configuração do Firebase (obrigatória antes de correr a app)

`lib/firebase_options.dart` é um placeholder que lança erro em runtime — tem de ser substituído pelo ficheiro real gerado para o teu projeto Firebase:

1. Criar um projeto em [console.firebase.google.com](https://console.firebase.google.com).
2. Ativar **Authentication → Sign-in method → Email/Password**.
3. Criar uma base de dados **Firestore** (modo produção).
4. Publicar o conteúdo de `firestore.rules` (raiz do repositório) no separador **Regras** do Firestore.
5. `npm install -g firebase-tools && dart pub global activate flutterfire_cli`, depois `firebase login` e `flutterfire configure` na raiz do projeto — isto gera o `lib/firebase_options.dart` real.

## Estrutura

```
lib/
├── main.dart              # entry point — Firebase.initializeApp() ANTES do runApp
├── firebase_options.dart  # gerado por `flutterfire configure` (placeholder até lá)
├── app_state.dart         # rootTabController — navegação global entre separadores
├── app_stores.dart        # AppointmentsStore, HistoryStore, NotificationSettings,
│                           #  appLanguageController — cada um com listenTo(uid)/
│                           #  stopListening(), espelhados em Firestore em tempo real
├── auth/auth_service.dart # AuthService — único ponto de contacto com FirebaseAuth
├── theme/app_theme.dart   # cores e tipografia (AppColors, AppTheme)
├── models/                # QueueLocation, ServiceItem, Appointment, Visit
├── data/mock_data.dart    # dados mock (bancos, serviços, senhas, contactos de suporte)
├── screens/                # ~23 ecrãs — ver lista abaixo (inclui AuthGate/Login/Signup)
└── widgets/                # componentes reutilizáveis (cards, botões, nav bar,
                             #  confirm_dialog, contact_sheet)
```

- `Imagensdeecrans/` — mockups de referência (gerados fora do projeto) que guiaram o design "FilaJá"/"Fila Certa".
- `scripts/serve_web.js` — servidor estático simples para pré-visualizar `flutter build web` localmente.
- `firestore.rules` — regras de segurança do Firestore (cada utilizador só acede a `users/{uid}/**` com o seu próprio `uid`); publicar manualmente no consola do Firebase, não é aplicado automaticamente.
- Cada `QueueLocation` tem o seu próprio `services: List<ServiceItem>` — os bancos (BPC/BFA/BAI/BCI) partilham `MockData.bankServices`; o SIAC usa `MockData.siacServices`, um catálogo real (Bilhete de Identidade, Registo Civil, Trânsito/DTSER, Passaporte/SME, Cartório Notarial, Registo Automóvel, Registo Comercial, Registo Predial, NIF/AGT, INSS, Ficheiro Central, CAEC, Administração Distrital). Ao adicionar uma localização nova, nunca reaproveitar `bankServices` para um tipo de balcão diferente — criar (ou escolher) a lista de serviços certa para esse tipo de entidade.

### Contas e sincronização (Firebase)

`lib/auth/auth_service.dart` (`AuthService`, instância global mutável `authService`) é o único ponto de contacto com `FirebaseAuth` — `signUp`/`signIn`/`signOut`/`sendPasswordReset`, todos devolvendo uma mensagem de erro em português (ou `null` em sucesso) em vez de lançarem exceções, via `_message(code)`. `lib/screens/auth_gate.dart` decide entre `LoginScreen`/`SignupScreen` e `RootShell` conforme `authService.userChanges`, semeando o estado inicial a partir de `authService.currentUser` (algumas implementações de `Stream<User?>`, incluindo `firebase_auth_mocks` nos testes, não repetem o estado já autenticado a um listener tardio).

Cada store em `app_stores.dart` (`AppointmentsStore`, `HistoryStore`, `NotificationSettings`, `AppLanguageController`) tem `listenTo(uid)`/`stopListening()`, chamados por `AuthGate` via `startUserDataSync(uid)`/`stopUserDataSync()` quando a sessão muda. Cada mutação (`add`/`cancel`/`toggle`/`setLanguage`/`clearAll`) escreve em Firestore sob `users/{uid}/...` (fire-and-forget via `unawaited(...)`, exceto `clearAll` que é `await`ado) — a UI atualiza-se otimisticamente em memória e depois o listener do Firestore confirma/sincroniza. Um `Appointment` grava `locationMonogram`+`serviceName` (resolvidos de volta contra `MockData` ao ler; se a localização/serviço já não existir no catálogo atual, esse registo é ignorado em silêncio). Um `Visit` grava campos soltos (`bank`, `monogram`, `service` como texto) — a `color` é sempre recalculada a partir do `monogram` atual em `MockData`, nunca gravada. A instância do Firestore usada por todos os stores é a variável mutável `firestoreInstance` (não `FirebaseFirestore.instance` diretamente) — testes apontam-na para uma `FakeFirebaseFirestore`.

### Ecrãs

Fluxo de autenticação: AuthGate → LoginScreen ↔ SignupScreen → RootShell.
Fluxo do cliente: Home → ChooseLocation → ChooseService → Queue → Almost → Called → Rating.
Fluxo de agendamento (reutiliza ChooseLocation/ChooseService com `isScheduling: true`): ChooseLocation → ChooseService → ScheduleDateTime → AppointmentConfirmed → AppointmentDetail (a partir da lista em Agendamentos).
Separadores: Home, MyAppointments (histórico, alimentado por `historyStore`), Schedule (agendamentos, alimentado por `appointmentsStore`), Profile.
A partir do Perfil: NotificationSettings, Settings (idioma + limpar todos os dados da conta), Help (FAQ + contacto), About, VisitDetail (a partir do histórico), Terminar sessão (`authService.signOut()`).

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
- Cada teste chama `_signInFakeUser()` (helper no topo do ficheiro) em `setUp()`, que aponta as duas globais mutáveis — `authService` (`lib/auth/auth_service.dart`) e `firestoreInstance` (`lib/app_stores.dart`) — para um `MockFirebaseAuth` já autenticado (`firebase_auth_mocks`) e uma `FakeFirebaseFirestore` (`fake_cloud_firestore`) pré-semeada com os mesmos agendamentos/histórico que os antigos seeds locais tinham. Isto faz o `AuthGate` ir direto a `RootShell` sem precisar de um projeto Firebase real durante os testes.
- **Os testes usam sempre `tester.view.physicalSize` com uma largura realista de telemóvel (390px), nunca a largura de teste por defeito (~800px)** — a largura por defeito esconde overflows que só aparecem num telemóvel real.
- Para telas por onde um botão possa ficar perto do fundo de um `ListView` longo, preferir um viewport de teste **alto** (`tester.view.physicalSize = const Size(390, h_grande)`) em vez de `tester.ensureVisible()` — este último pode acertar noutra camada da interface (chrome do `Scaffold`) em vez do widget alvo.
- Para fechar um ecrã aberto com `ScreenHeader`, usar `tester.tap(find.byIcon(Icons.arrow_back))` — `tester.pageBack()` não reconhece este botão próprio (não é um `BackButton`/`AppBar` standard do Flutter).

## O que NÃO alterar sem confirmação

- Dados mock em `lib/data/mock_data.dart` — refletem os mockups originais em `Imagensdeecrans/`; alterações de conteúdo devem ser deliberadas, não incidentais.
- Não foi implementado modo escuro deliberadamente: `AppColors` são constantes estáticas referenciadas diretamente em todos os ecrãs (não vêm de `Theme.of(context)`), por isso um toggle de tema não teria efeito visual real sem reescrever todos os ecrãs — não adicionar um toggle "fake" no Settings sem fazer essa reescrita primeiro.

## Histórico de nomenclatura

O projeto chamou-se inicialmente "FilaJá"; a marca foi depois alterada para "Fila Certa" em todos os aspectos — identificador do pacote Dart (`fila_certa_app`), `applicationId`/`namespace` Android (`com.example.fila_certa_app`), bundle id iOS/macOS (`com.example.filaCertaApp`), nomes de produto Windows/Linux, classes Dart (`FilaCertaApp`, `FilaCertaBottomNav`) e todo o texto visível. Não deve restar nenhuma referência a "filaja"/"FilaJá" no código — se encontrares alguma, é um resíduo a corrigir.

## Estado atual

Protótipo funcional e interativo, **com contas de utilizador reais e sincronização entre dispositivos** via Firebase (Auth + Firestore) — entrar/criar conta com email e palavra-passe, agendamentos/histórico/preferências ligados à conta, não ao aparelho. Todos os ecrãs do fluxo do cliente e de agendamento estão implementados e ligados (sem botões "mortos"). Ações de contacto (telefone, WhatsApp, email, mapas) abrem apps reais do dispositivo via `url_launcher`. `lib/firebase_options.dart` é ainda um placeholder — a app só liga a um projeto Firebase real depois de correr `flutterfire configure` (ver secção "Configuração do Firebase" acima). Não existem ainda os lados de atendente/supervisor/painel TV (esses existem apenas como conceito visual noutro artefacto, fora deste repositório Flutter).
