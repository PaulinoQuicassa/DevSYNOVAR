# Fila Certa

App cliente Flutter de uma plataforma de gestão inteligente de filas e atendimento (mercado angolano). Fluxo completo de entrada em fila, agendamento, acompanhamento e avaliação. Seis instituições reais (Banco Exemplo, BPC, BFA, BAI, BCI, SIAC) já estão activas em produção — só as localizações/serviços em si continuam com dados estáticos (`lib/data/mock_data.dart`).

**Backend: 100% Supabase** (Postgres + Auth + Realtime). Não há Firebase neste repositório — foi completamente removido (ver `docs/frontend-migration-audit.md` no repo irmão `fila-certa-staff` para o histórico da migração).

## Stack

- Flutter 3.47.1 · Dart >=3.3.0 · Material 3
- Dependências: `google_fonts`, `cupertino_icons`, `url_launcher`, `qr_flutter`, `geolocator`, `supabase_flutter`
- Dados de localizações/serviços continuam estáticos (`lib/data/mock_data.dart`); os dados reais (senhas, agendamentos, histórico, notificações, preferências) vivem no Postgres do Supabase, protegidos por RLS (`is_staff_of_branch`/`customer_id = auth.uid()`, ver `docs/security-rls.md` no repo irmão).

## Configuração do Supabase

`lib/supabase_client.dart` tem a URL e a "publishable key" do projecto real (`qdfpqispcntitvczybfl`) — não são secretas, o controlo de acesso vive nas políticas RLS, não na chave. Não é preciso nenhum passo de configuração adicional para correr a app; `main.dart` chama `Supabase.initialize(...)` antes do `runApp`.

## Estrutura

```
lib/
├── main.dart                # entry point — Supabase.initialize() ANTES do runApp
├── supabase_client.dart     # URL/publishable key + getter supabaseClient
├── app_state.dart           # rootTabController, activeTicketStore — navegação/estado global
├── app_stores.dart          # AppointmentsStore, NotificationsStore, NotificationSettings,
│                             #  AppLanguageController — cada um com listenTo(uid)/
│                             #  stopListening(), espelhados em Postgres (Realtime + poll
│                             #  para agregados)
├── ticket_service.dart      # camada de acesso ao ciclo de vida real de uma senha —
│                             #  RPCs para mutação, postgres_changes/poll para leitura
├── auth/auth_service.dart   # AuthService — único ponto de contacto com SupabaseClient.auth
├── theme/app_theme.dart     # cores e tipografia (AppColors, AppTheme)
├── models/                  # QueueLocation, ServiceItem, Appointment, Visit, LiveTicket,
│                             #  MyTicket, AppNotification
├── data/mock_data.dart      # localizações/serviços (6 já ligadas a institutionId/branchId reais)
├── screens/                  # ~25 ecrãs (inclui AuthGate/Login/Signup)
└── widgets/                  # componentes reutilizáveis, incl. global_queue_alerts.dart
                               #  (avisos em tempo real de todas as acções do balcão)
```

- `Imagensdeecrans/` — mockups de referência (gerados fora do projecto) que guiaram o design.
- `scripts/serve_web.js` — servidor estático simples para pré-visualizar `flutter build web` localmente.
- Cada `QueueLocation` tem o seu próprio `services: List<ServiceItem>` — os bancos partilham `MockData.bankServices`; o SIAC usa `MockData.siacServices` (catálogo real de 13 serviços). Ao adicionar uma localização nova, nunca reaproveitar `bankServices` para um tipo de balcão diferente.

### Contas e sincronização (Supabase)

`lib/auth/auth_service.dart` (`AuthService`, instância global mutável `authService`) é o único ponto de contacto com `SupabaseClient.auth` — `signUp`/`signIn`/`signOut`/`sendPasswordReset`, todos devolvendo uma mensagem de erro em português (ou `null` em sucesso). `lib/screens/auth_gate.dart` decide entre `LoginScreen`/`SignupScreen` e `RootShell` conforme `authService.userChanges`, semeando o estado inicial a partir de `authService.currentUser` de forma síncrona (um `onAuthStateChange` recém-subscrito não garante repetir o estado já autenticado).

Cada store em `app_stores.dart` (`AppointmentsStore`, `NotificationsStore`, `NotificationSettings`, `AppLanguageController`) tem `listenTo(uid)`/`stopListening()`, chamados por `AuthGate` via `startUserDataSync(uid)`/`stopUserDataSync()` quando a sessão muda. As tabelas envolvidas (`appointments`, `notifications`, `user_settings`) usam `postgres_changes` com refetch completo a cada evento — nunca lógica de negócio no listener. `HistoryStore` já não persiste (superado por "Os meus atendimentos", que lê directamente as senhas reais do cliente via `ticket_service.subscribeMyTickets`) — fica só em memória de sessão.

Toda a lógica crítica da fila (tirar senha, chamar, concluir, transferir, cancelar, "estou a caminho") passa por funções RPC `SECURITY DEFINER` no Postgres (`pull_ticket`, `call_next`, `complete_current`, `transfer_ticket`, `cancel_ticket`, `set_on_the_way`, etc.) — o Flutter nunca decide o estado da fila, só chama a RPC e interpreta o resultado.

### Ecrãs

Fluxo de autenticação: AuthGate → LoginScreen ↔ SignupScreen → RootShell.
Fluxo do cliente: Home → ChooseLocation → ChooseService → Queue → Almost → Called → Rating.
Fluxo de agendamento (reutiliza ChooseLocation/ChooseService com `isScheduling: true`): ChooseLocation → ChooseService → ScheduleDateTime → AppointmentConfirmed → AppointmentDetail.
Separadores: Home, MyAppointments (histórico real ao vivo, `ticket_service.subscribeMyTickets`), Schedule (agendamentos, `appointmentsStore`), Profile.
A partir do Perfil: NotificationsScreen (inbox real + preferências), Settings (idioma + limpar dados), Help, About, VisitDetail, Terminar sessão.

## Convenções observadas

- Sem gestor de estado externo (Provider/Riverpod/Bloc) — estado local via `setState`, estado partilhado via `ValueNotifier`/`ChangeNotifier` globais.
- Camada de dados sempre via `ticket_service.dart`/`app_stores.dart` (nunca `supabaseClient` directamente dentro de um widget/ecrã) — mantém a separação UI → Repository/Data Source.
- Cada widget/ecrã tem construtor `const` sempre que os campos o permitem.
- Design tokens centralizados em `AppColors`/`AppTheme` (`lib/theme/app_theme.dart`).
- Navegação da fila e do agendamento usa `Navigator.push` normal (root navigator), mantendo a barra inferior via `FlowScaffold`.
- Texto/label num `Row` que pode crescer deve ir dentro de `Flexible`/`Expanded` com `overflow: TextOverflow.ellipsis`.
- Ações que alteram estado do utilizador pedem confirmação via `confirmAction` (`lib/widgets/confirm_dialog.dart`).
- Contacto com bancos/suporte usa `showContactSheet`/`openMapsDirections`, que abrem apps reais via `url_launcher`.

## Comandos

```bash
flutter pub get      # instalar dependências
flutter analyze      # lint/type-check — deve devolver "No issues found!"
flutter test         # correr testes
flutter run          # correr num dispositivo/emulador
flutter build web    # build de produção para browser
```

## Testes

- `test/widget_test.dart`: os 4 cenários (smoke test, agendamento ponta a ponta, catálogo SIAC, navegação completa) estão marcados **`skip`** — dependiam de `fake_cloud_firestore`/`firebase_auth_mocks`, sem equivalente maduro para simular Supabase localmente, e sem Docker disponível nesta máquina para um Supabase local. Ver `docs/testing.md` (repo `fila-certa-staff`) para a estratégia de substituição e o que já foi compensado por testes de integração reais (scripts Node contra o projecto Supabase ao vivo).
- Validação funcional real feita via scripts em `fila-certa-staff/scripts/*.mjs` (RPCs, Realtime, RLS, concorrência) — não via `flutter test`.

## O que NÃO alterar sem confirmação

- Dados mock em `lib/data/mock_data.dart` — alterações de conteúdo devem ser deliberadas.
- Não foi implementado modo escuro deliberadamente — não adicionar um toggle "fake" no Settings.
- Não reintroduzir nenhuma dependência Firebase (`firebase_core`, `firebase_auth`, `cloud_firestore`, ficheiros `firebase_options.dart`/`google-services.json`) — foram removidos definitivamente; qualquer necessidade nova de backend passa pelo Supabase.

## Histórico de nomenclatura

O projecto chamou-se inicialmente "FilaJá"; a marca foi depois alterada para "Fila Certa" em todos os aspectos. Não deve restar nenhuma referência a "filaja"/"FilaJá" no código.

## Publicar (GitHub Pages)

O alojamento não é Firebase Hosting (removido em 2026-09-07) -- é
GitHub Pages, servido a partir de uma branch órfã `gh-pages` deste
repositório (repositório público, exigido pelo plano gratuito do
GitHub Pages).

```bash
MSYS_NO_PATHCONV=1 flutter build web --release --base-href /DevSYNOVAR/
cp build/web/index.html build/web/404.html   # fallback de SPA
touch build/web/.nojekyll
# depois: copiar build/web/ para uma worktree da branch gh-pages, commit, push -f
```

URL publicado: https://paulinoquicassa.github.io/DevSYNOVAR/

## Estado atual

App funcional e interactiva, com contas de utilizador reais via Supabase Auth, sincronização entre dispositivos, e seis instituições reais em produção (fila, agendamentos, avaliações, notificações — tudo ligado a dados reais no Postgres). Lado de atendente/gestor existe num repositório irmão (`fila-certa-staff`, React), já também migrado para Supabase. Firebase foi completamente removido dos dois repositórios (código e hosting) -- só falta eliminar o projecto Firebase Cloud em si, pendente de acção manual do utilizador (a credencial de serviço disponível não tem permissão de Owner).
