import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fila_certa_app/app_state.dart';
import 'package:fila_certa_app/app_stores.dart';
import 'package:fila_certa_app/data/mock_data.dart';
import 'package:fila_certa_app/main.dart';

void main() {
  setUp(() {
    // Widget tests build FilaCertaApp directly (bypassing main()), so
    // hydrateAllStores() never runs here — but store methods still fire
    // SharedPreferences writes. This gives them an in-memory fake instead
    // of hitting a real (unavailable) platform channel.
    SharedPreferences.setMockInitialValues({});
    rootTabController.value = 0;
    appointmentsStore.reset();
    historyStore.reset();
  });

  testWidgets('Fila Certa home screen renders and the queue flow can be opened', (WidgetTester tester) async {
    // A realistic (narrow) phone width — the default test surface is much
    // wider than a real phone and would hide layout overflow that only
    // shows up on an actual device.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FilaCertaApp());
    await tester.pumpAndSettle();

    expect(find.text('Fila Certa'), findsOneWidget);
    expect(find.text('Entrar numa fila'), findsOneWidget);

    await tester.tap(find.text('Entrar numa fila'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher localização'), findsOneWidget);
  });

  testWidgets('a new appointment can be scheduled end-to-end and shows up in Agendamentos', (WidgetTester tester) async {
    // Tall viewport so every screen in this flow fits without scrolling —
    // avoids relying on Scrollable.ensureVisible for elements that sit low
    // on long ListView screens (confirm buttons, QR card, etc).
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FilaCertaApp());
    await tester.pumpAndSettle();

    // Go to the Agendamentos tab.
    await tester.tap(find.text('Agendamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Marque hora e evite esperar na fila.'), findsOneWidget);

    // Start a new appointment.
    await tester.tap(find.text('Novo agendamento'));
    await tester.pumpAndSettle();
    expect(find.text('Selecione o local onde deseja ser atendido.'), findsOneWidget);

    final location = MockData.locations.first;
    await tester.tap(find.text(location.name));
    await tester.pumpAndSettle();
    expect(find.text('Selecione o serviço que pretende.'), findsOneWidget);

    final service = location.services.first;
    await tester.tap(find.text(service.name));
    await tester.pumpAndSettle();
    expect(find.text('Escolher data'), findsOneWidget);
    expect(find.text('Escolher hora'), findsOneWidget);

    final firstDayLabel = DateTime.now().add(const Duration(days: 1)).day.toString();
    await tester.tap(find.text(firstDayLabel));
    await tester.pumpAndSettle();

    final firstSlot = MockData.timeSlots.first;
    await tester.tap(find.text(firstSlot));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirmar agendamento'));
    await tester.pumpAndSettle();

    expect(find.text('Agendamento confirmado'), findsOneWidget);
    expect(find.text(service.name), findsWidgets);

    await tester.tap(find.text('Concluir'));
    await tester.pumpAndSettle();

    // Back on Agendamentos, the freshly created appointment is now listed.
    expect(find.text('Marque hora e evite esperar na fila.'), findsOneWidget);
    expect(find.text(location.name), findsOneWidget);
  });

  testWidgets('SIAC shows its own real service catalogue, not the bank services', (WidgetTester tester) async {
    // A realistic (narrow) phone width — the default test surface is much
    // wider than a real phone and would hide a RenderFlex overflow in the
    // service card grid that only shows up on an actual device.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FilaCertaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar numa fila'));
    await tester.pumpAndSettle();

    final siac = MockData.locations.firstWhere((l) => l.monogram == 'SIAC');
    await tester.tap(find.text(siac.name));
    await tester.pumpAndSettle();

    // Real SIAC services show up...
    expect(find.text('Bilhete de Identidade'), findsOneWidget);
    expect(find.text('Passaporte e Residência'), findsOneWidget);
    expect(find.text('NIF — AGT'), findsOneWidget);

    // ...and bank-only services don't leak into the citizen service centre.
    expect(find.text('Depósitos e Levantamentos'), findsNothing);
    expect(find.text('Crédito Habitação'), findsNothing);
  });

  testWidgets('every reachable screen in the app renders without layout errors', (WidgetTester tester) async {
    // Realistic narrow phone width, tall enough that long screens (Called,
    // Almost, service grids) don't need scrolling for this test's taps.
    tester.view.physicalSize = const Size(390, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FilaCertaApp());
    await tester.pumpAndSettle();

    // --- Os meus atendimentos tab -> a history entry's detail screen ---
    await tester.tap(find.text('Os meus\natendimentos'));
    await tester.pumpAndSettle();
    expect(find.text('Os meus atendimentos'), findsOneWidget);

    await tester.tap(find.text('Banco de Poupança e Crédito (BPC)'));
    await tester.pumpAndSettle();
    expect(find.text('Detalhe do atendimento'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // --- Agendamentos tab -> an existing appointment's detail screen ---
    await tester.tap(find.text('Agendamentos'));
    await tester.pumpAndSettle();
    expect(find.text('Marque hora e evite esperar na fila.'), findsOneWidget);

    final baiName = MockData.locations[2].name;
    await tester.tap(find.text(baiName));
    await tester.pumpAndSettle();
    expect(find.text('Detalhe do agendamento'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // --- Perfil tab and every screen reachable from it ---
    await tester.tap(find.text('Perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Paulino Quicassa'), findsOneWidget);

    await tester.tap(find.text('Notificações'));
    await tester.pumpAndSettle();
    expect(find.text('Alertas de fila'), findsOneWidget);
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Definições'));
    await tester.pumpAndSettle();
    expect(find.text('Unidade de distância'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Ajuda e suporte'));
    await tester.pumpAndSettle();
    expect(find.text('Perguntas frequentes'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sobre a Fila Certa'));
    await tester.pumpAndSettle();
    expect(find.text('Versão 1.0.0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    // --- Back to Início, then the full queue flow through to Avaliação ---
    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Entrar numa fila'));
    await tester.pumpAndSettle();

    final bpc = MockData.locations.first;
    await tester.tap(find.text(bpc.name));
    await tester.pumpAndSettle();

    await tester.tap(find.text(bpc.services.first.name));
    await tester.pumpAndSettle();
    expect(find.text('Acompanhar fila'), findsOneWidget);

    await tester.tap(find.text('Acompanhar fila'));
    await tester.pumpAndSettle();
    expect(find.text('Está quase na sua vez!'), findsOneWidget);

    await tester.tap(find.text('Está quase na sua vez!'));
    await tester.pumpAndSettle();
    expect(find.text('Estou a caminho'), findsOneWidget);

    await tester.tap(find.text('Estou a caminho'));
    await tester.pumpAndSettle();
    expect(find.text('Como foi o seu atendimento?'), findsOneWidget);
  });
}
