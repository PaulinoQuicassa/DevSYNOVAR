import 'package:flutter_test/flutter_test.dart';

import 'package:filaja_app/main.dart';

void main() {
  testWidgets('Fila Certa home screen renders and the queue flow can be opened', (WidgetTester tester) async {
    await tester.pumpWidget(const FilajaApp());
    await tester.pumpAndSettle();

    expect(find.text('Fila Certa'), findsOneWidget);
    expect(find.text('Entrar numa fila'), findsOneWidget);

    await tester.tap(find.text('Entrar numa fila'));
    await tester.pumpAndSettle();

    expect(find.text('Escolher localização'), findsOneWidget);
  });
}
