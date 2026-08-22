import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fila_certa_app/app_state.dart';
import 'package:fila_certa_app/app_stores.dart';
import 'package:fila_certa_app/data/mock_data.dart';
import 'package:fila_certa_app/main.dart';

void main() {
  setUp(() {
    rootTabController.value = 0;
    appointmentsStore.reset();
    historyStore.reset();
  });

  testWidgets('Fila Certa home screen renders and the queue flow can be opened', (WidgetTester tester) async {
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
    tester.view.physicalSize = const Size(430, 2200);
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
}
