# Fila Certa

Protótipo Flutter de uma plataforma de gestão inteligente de filas e atendimento (mercado angolano). App cliente com fluxo completo de entrada em fila, agendamento, acompanhamento e avaliação, usando dados mock — sem backend nem base de dados real. Estado (agendamentos, histórico, notificações) é local à sessão da app.

## Stack

- Flutter 3.47.1 · Dart >=3.3.0 · Material 3
- Dependências: `google_fonts`, `cupertino_icons`, `url_launcher` (chamar, WhatsApp, email, mapas — abre apps reais do dispositivo), `qr_flutter` (QR code real e legível nos agendamentos)
- Sem backend/API/DB/auth — dados mock em `lib/data/mock_data.dart`, estado mutável em `lib/app_stores.dart`

## Estrutura

```
lib/
├── main.dart              # entry point (FilaCertaApp)
├── app_state.dart         # rootTabController — navegação global entre separadores
├── app_stores.dart        # AppointmentsStore, HistoryStore, NotificationSettings,
│                           #  appLanguageController — estado mutável em memória (sem persistência)
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
- Texto/label num `Row` que pode crescer (nomes, datas formatadas, labels dinâmicos) deve ir dentro de `Flexible`/`Expanded` com `overflow: TextOverflow.ellipsis` — já houve overflow real em ecrãs estreitos por esquecer isto (ver `GradientButton`, `LocationSummaryCard`, `ServiceCard`).
- Ações que alteram estado do utilizador (sair da fila, cancelar agendamento, não comparecer, terminar sessão) pedem confirmação via `confirmAction` (`lib/widgets/confirm_dialog.dart`) antes de executar.
- Contacto com bancos/suporte usa `showContactSheet`/`openMapsDirections` (`lib/widgets/contact_sheet.dart`), que abrem apps reais via `url_launcher` — não simular com `SnackBar`.

## Comandos

```bash
flutter pub get      # instalar dependências
flutter analyze      # lint/type-check — deve devolver "No issues found!"
flutter test         # correr testes (2 suites)
flutter run          # correr num dispositivo/emulador
flutter build web    # build de produção para browser
```

## Testes

- `test/widget_test.dart` — 2 suites:
  1. Smoke test: a Home renderiza e o botão "Entrar numa fila" navega para "Escolher localização".
  2. Fluxo completo: agendar um novo atendimento de ponta a ponta (escolher local/serviço/data/hora, confirmar, ver o código+QR, e confirmar que aparece na lista de Agendamentos).
- Os testes usam `appointmentsStore.reset()`/`historyStore.reset()` em `setUp()` para começarem sempre do mesmo estado — qualquer novo `ValueNotifier` global mutável deve seguir o mesmo padrão (método `reset()` + reset no `setUp` do teste).
- O teste do fluxo de agendamento define um viewport de teste alto (`tester.view.physicalSize`) para evitar problemas de scroll/hit-test em ecrãs longos — reutilizar esse padrão em vez de `ensureVisible` para novos testes end-to-end.
- Sem testes unitários de modelos/widgets isolados ainda.

## O que NÃO alterar sem confirmação

- Dados mock em `lib/data/mock_data.dart` — refletem os mockups originais em `Imagensdeecrans/`; alterações de conteúdo devem ser deliberadas, não incidentais.
- Não foi implementado modo escuro deliberadamente: `AppColors` são constantes estáticas referenciadas diretamente em todos os ecrãs (não vêm de `Theme.of(context)`), por isso um toggle de tema não teria efeito visual real sem reescrever todos os ecrãs — não adicionar um toggle "fake" no Settings sem fazer essa reescrita primeiro.

## Histórico de nomenclatura

O projeto chamou-se inicialmente "FilaJá"; a marca foi depois alterada para "Fila Certa" em todos os aspectos — identificador do pacote Dart (`fila_certa_app`), `applicationId`/`namespace` Android (`com.example.fila_certa_app`), bundle id iOS/macOS (`com.example.filaCertaApp`), nomes de produto Windows/Linux, classes Dart (`FilaCertaApp`, `FilaCertaBottomNav`) e todo o texto visível. Não deve restar nenhuma referência a "filaja"/"FilaJá" no código — se encontrares alguma, é um resíduo a corrigir.

## Estado atual

Protótipo funcional e interativo, sem persistência entre sessões (fecha a app e os agendamentos/histórico voltam ao estado inicial — ver "Repor dados de demonstração" em Definições). Todos os ecrãs do fluxo do cliente e de agendamento estão implementados e ligados (sem botões "mortos"). Ações de contacto (telefone, WhatsApp, email, mapas) abrem apps reais do dispositivo via `url_launcher`. Não existem ainda os lados de atendente/supervisor/painel TV (esses existem apenas como conceito visual noutro artefacto, fora deste repositório Flutter).
