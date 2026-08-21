# Fila Certa

Protótipo Flutter de uma plataforma de gestão inteligente de filas e atendimento (mercado angolano). App cliente com fluxo completo de entrada em fila, acompanhamento e avaliação, usando dados mock — sem backend, base de dados ou autenticação.

## Stack

- Flutter 3.47.1 · Dart >=3.3.0 · Material 3
- Dependências: `google_fonts`, `cupertino_icons`
- Sem backend/API/DB/auth — dados 100% mock em `lib/data/mock_data.dart`

## Estrutura

```
lib/
├── main.dart              # entry point (FilajaApp)
├── app_state.dart         # rootTabController — navegação global entre separadores
├── theme/app_theme.dart   # cores e tipografia (AppColors, AppTheme)
├── models/                # QueueLocation, ServiceItem
├── data/mock_data.dart    # dados mock (bancos, serviços, senhas)
├── screens/                # 10 ecrãs (Home, ChooseLocation, ChooseService, Queue,
│                            #  Almost, Called, Rating, MyAppointments, Schedule,
│                            #  Profile, RootShell)
└── widgets/                # 11 componentes reutilizáveis (cards, botões, nav bar)
```

- `Imagensdeecrans/` — mockups de referência (gerados fora do projeto) que guiaram o design "FilaJá"/"Fila Certa".
- `scripts/serve_web.js` — servidor estático simples para pré-visualizar `flutter build web` localmente.

## Convenções observadas

- Sem gestor de estado externo (Provider/Riverpod/Bloc) — estado local via `setState`, navegação global via um `ValueNotifier<int>` (`rootTabController`).
- Cada widget/ecrã tem construtor `const` sempre que os campos o permitem.
- Design tokens centralizados em `AppColors`/`AppTheme` (`lib/theme/app_theme.dart`) — evitar cores/hex soltos nos ecrãs.
- Navegação da fila usa `Navigator.push` normal (root navigator), mantendo a barra inferior via `FlowScaffold` em cada ecrã do fluxo.

## Comandos

```bash
flutter pub get      # instalar dependências
flutter analyze      # lint/type-check — deve devolver "No issues found!"
flutter test         # correr testes (1 suite)
flutter run          # correr num dispositivo/emulador
flutter build web    # build de produção para browser
```

## Testes

- `test/widget_test.dart` — smoke test único: confirma que a Home renderiza e que o botão "Entrar numa fila" navega para "Escolher localização".
- Sem testes unitários de modelos/widgets isolados ainda.

## O que NÃO alterar sem confirmação

- Nome do pacote (`filaja_app` em `pubspec.yaml`) — decisão explícita de manter por agora, apesar do nome visível da app ser "Fila Certa" (ver commit de organização do Claude Code).
- Dados mock em `lib/data/mock_data.dart` — refletem os mockups originais em `Imagensdeecrans/`; alterações de conteúdo devem ser deliberadas, não incidentais.

## Estado atual

Protótipo funcional, sem persistência real. Todos os ecrãs do fluxo principal do cliente estão implementados; não existem ainda os lados de atendente/supervisor/painel TV (esses existem apenas como conceito visual noutro artefacto, fora deste repositório Flutter).
