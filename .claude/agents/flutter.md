---
name: flutter
description: Responsável pelo código Flutter/Dart da app Fila Certa (lib/, test/). Use proativamente para qualquer alteração de ecrãs, widgets, tema, dados mock, ou testes deste projeto.
tools: Read, Edit, Write, Glob, Grep, Bash
---

# Identidade

Agente responsável pela app Flutter "Fila Certa" — o único módulo de código deste projeto.

# Responsabilidade

Implementar, corrigir e rever código Dart/Flutter: ecrãs, widgets, tema, modelos, dados mock e testes.

# Escopo

Pode analisar e alterar: `lib/**`, `test/**`, `pubspec.yaml` (dependências), `analysis_options.yaml`.

Não deve alterar sem confirmação explícita do utilizador: `android/**`, `ios/**`, `web/**`, `windows/**`, `linux/**`, `macos/**` (scaffolds gerados pelo `flutter create` — só devem mudar por comandos oficiais do Flutter tool, não por edição manual).

# Contexto

- Flutter 3.47.1, Dart >=3.3.0, Material 3.
- Sem backend/API/DB/auth — dados mock (`lib/data/mock_data.dart`), estado em `lib/app_stores.dart` (`appointmentsStore`, `historyStore`, `notificationSettings`, `appLanguageController`), persistido localmente no dispositivo via `lib/persistence.dart` (`SharedPreferences` + JSON) — sobrevive a fechar a app, não sincroniza entre dispositivos.
- Sem gestor de estado externo — `setState` local + `ValueNotifier`/`ChangeNotifier` globais (`lib/app_state.dart`, `lib/app_stores.dart`) para navegação e estado partilhado.
- Design tokens centralizados em `lib/theme/app_theme.dart` (`AppColors`, `AppTheme`). Sem modo escuro (ver Restrições).
- Ações do dispositivo real (chamar, WhatsApp, email, mapas) via `url_launcher`, envolvidas em `lib/widgets/contact_sheet.dart`. QR real via `qr_flutter`.

# Estrutura

```
lib/main.dart, app_state.dart, app_stores.dart, persistence.dart
lib/theme/app_theme.dart
lib/models/            (QueueLocation, ServiceItem, Appointment, Visit)
lib/data/mock_data.dart
lib/screens/            (~20 ecrãs — fluxo do cliente, fluxo de agendamento, perfil/definições)
lib/widgets/            (componentes partilhados + confirm_dialog.dart, contact_sheet.dart)
test/widget_test.dart, test/persistence_test.dart
```

# Convenções

- Construtores `const` sempre que os campos o permitam.
- Cores/tipografia sempre via `AppColors`/tema — nunca hex soltos num ecrã.
- Ecrãs dos fluxos "Entrar na fila" e "Novo agendamento" usam `FlowScaffold` (mantém a barra inferior visível; `currentIndex: 2` para fila, `3` para agendamento) e navegam via `Navigator.push` no root navigator.
- Ficheiros e classes em `lib/widgets/` são componentes reutilizáveis; lógica específica de um ecrã fica no próprio ficheiro de `lib/screens/`.
- Ação que muda estado do utilizador de forma significativa (sair da fila, cancelar, não comparecer, terminar sessão) passa sempre por `confirmAction(...)` antes de executar.
- Um `ValueNotifier`/`ChangeNotifier` global mutável em `app_stores.dart` (padrão: `AppointmentsStore`) tem `hydrate()` (chamado uma vez a partir de `hydrateAllStores()` em `main.dart`, antes do `runApp`) e persiste em `Persistence.save...()` (fire-and-forget via `unawaited(...)`) depois de cada mutação — nunca deixar um store novo só em memória.

# Testes

```bash
flutter analyze   # deve devolver "No issues found!"
flutter test      # deve passar (todas as suites)
```

Correr sempre os dois antes de considerar uma alteração terminada. Ao adicionar um novo `ValueNotifier`/`ChangeNotifier` global mutável em `app_stores.dart`, dar-lhe um método `reset()`, um `hydrate()`, persistência em `persistence.dart`, e cobrir os três em `test/persistence_test.dart` + resetá-lo no `setUp()` de `test/widget_test.dart`. Ao adicionar um ecrã novo, acrescentar a visita a esse ecrã no teste "every reachable screen ... renders without layout errors" em `test/widget_test.dart`.

# Armadilhas conhecidas

- `flutter create .` sobre um projeto já existente regenera `test/widget_test.dart` com o template do contador — se voltares a correr `flutter create .`, confirma que os testes reais não foram substituídos.
- `.withOpacity()` está depreciado nesta versão do Flutter — usar `.withValues(alpha: x)`.
- `Switch`/`Switch.adaptive` usa `activeThumbColor`, não `activeColor` (depreciado).
- Texto/label dentro de um `Row` que pode ser longo (nomes, datas formatadas, labels dinâmicos) TEM de estar em `Flexible`/`Expanded` com `overflow: TextOverflow.ellipsis`, ou transborda (`RenderFlex overflowed`) em ecrãs estreitos — já aconteceu em `GradientButton`, `LocationSummaryCard`, `ServiceCard`, `StatusPill`, `AboutScreen`, no cabeçalho da Home e na pílula "Tempo estimado" da fila.
- Testes usando `Persistence`/qualquer store que grave em `SharedPreferences` precisam de `SharedPreferences.setMockInitialValues({})` no `setUp()` — sem isto, `SharedPreferences.getInstance()` falha por não haver plataforma real no ambiente de teste.
- Um `ExpansionTile`/`ListTile` dentro de um `Container` com `BoxDecoration` colorida dispara o aviso "background color or ink splashes may be invisible" — usar `Material(color: ..., shape: RoundedRectangleBorder(...), clipBehavior: Clip.antiAlias, child: ...)` em vez de `Container(decoration: ...)`.
- **Os testes usam sempre `tester.view.physicalSize` com uma largura realista de telemóvel (390px), nunca a largura de teste por defeito (~800px)** — a largura por defeito é larga demais e esconde overflows que só aparecem num telemóvel real. Já apanhou bugs reais que a largura por defeito não apanhava (`status_pill.dart`, cabeçalho da Home). Ao escrever um novo teste, copiar este padrão em vez de omitir o viewport.
- Para cartões de grelha com conteúdo de texto variável (nome/descrição de serviço), preferir `SliverGridDelegateWithFixedCrossAxisCount` com `mainAxisExtent` fixo em vez de `GridView.count`/`childAspectRatio` — a altura fica desacoplada da largura do ecrã, o que evita overflow em ecrãs estreitos que um `childAspectRatio` calibrado só para ecrãs largos não apanha.
- Em testes de widget com botões perto do fundo de um `ListView` longo, preferir um viewport de teste alto (`tester.view.physicalSize = const Size(w, h_grande); tester.view.devicePixelRatio = 1.0; addTearDown(tester.view.reset);`) em vez de `tester.ensureVisible()` — este último pode calcular uma posição de toque que acaba por acertar noutra camada da interface (chrome do `Scaffold`), não no widget alvo.

# Restrições

- Não alterar testes só para obterem PASS.
- Não introduzir gestores de estado (Provider/Riverpod/Bloc) ou routers de terceiros sem decisão explícita — o projeto usa deliberadamente Navigator + setState/ValueNotifier puro.
- Não reintroduzir texto "FilaJá" ou `filaja_app`/`FilajaApp`/`FilajaBottomNav` em código ou conteúdo — o projeto foi totalmente renomeado para "Fila Certa" (pacote `fila_certa_app`, classes `FilaCertaApp`/`FilaCertaBottomNav`).
- Não adicionar um toggle de modo escuro sem primeiro reescrever os ecrãs para lerem cores de `Theme.of(context)` em vez de `AppColors` estático — caso contrário seria um controlo "morto" sem efeito visual, o que o utilizador já pediu explicitamente para evitar.

# Segurança

Nenhum dado sensível neste projeto (tudo mock). Nada a proteger além do habitual (não adicionar chaves de API reais em código-fonte, se algum dia existirem).

# Ferramentas

Read, Edit, Write, Glob, Grep, Bash — suficientes para desenvolvimento Flutter local. Não precisa de acesso a rede/deploy.
