import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fila_certa_app/data/mock_data.dart';
import 'package:fila_certa_app/models/appointment.dart';
import 'package:fila_certa_app/models/visit.dart';
import 'package:fila_certa_app/persistence.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('loadAppointments returns null when nothing was ever saved', () async {
    expect(await Persistence.loadAppointments(), isNull);
  });

  test('appointments round-trip through save/load, resolved back against MockData', () async {
    final siac = MockData.locations.firstWhere((l) => l.monogram == 'SIAC');
    final appointment = Appointment(
      code: 'AG-9001',
      location: siac,
      service: siac.services.first,
      date: DateTime(2026, 9, 3, 9, 0),
      time: '09:00',
    );

    await Persistence.saveAppointments([appointment]);
    final loaded = await Persistence.loadAppointments();

    expect(loaded, isNotNull);
    expect(loaded!.length, 1);
    expect(loaded.first.code, 'AG-9001');
    expect(loaded.first.location.monogram, 'SIAC');
    expect(loaded.first.service.name, siac.services.first.name);
    expect(loaded.first.date, DateTime(2026, 9, 3, 9, 0));
  });

  test('an empty appointments list persists as empty, not as "nothing saved"', () async {
    await Persistence.saveAppointments(const []);
    final loaded = await Persistence.loadAppointments();

    expect(loaded, isNotNull);
    expect(loaded, isEmpty);
  });

  test('visit history round-trips, and resolves its colour from the current MockData branding', () async {
    const visit = Visit(
      bank: 'Banco BFA',
      monogram: 'BFA',
      color: Color(0xFF000000), // deliberately wrong — load should recompute it
      service: 'Cartões',
      date: 'Hoje, 10:00',
      ticket: 'Z001',
      status: VisitStatus.completed,
      rating: 5,
    );

    await Persistence.saveHistory([visit]);
    final loaded = await Persistence.loadHistory();

    expect(loaded, isNotNull);
    expect(loaded!.single.bank, 'Banco BFA');
    expect(loaded.single.rating, 5);
    expect(loaded.single.status, VisitStatus.completed);
    expect(loaded.single.color, MockData.locations.firstWhere((l) => l.monogram == 'BFA').brandColor);
  });

  test('notification settings round-trip', () async {
    await Persistence.saveNotificationSettings({
      'queueAlerts': false,
      'appointmentReminders': true,
      'promotions': true,
      'whatsapp': false,
    });

    final loaded = await Persistence.loadNotificationSettings();
    expect(loaded, {
      'queueAlerts': false,
      'appointmentReminders': true,
      'promotions': true,
      'whatsapp': false,
    });
  });

  test('language preference round-trips', () async {
    expect(await Persistence.loadLanguage(), isNull);
    await Persistence.saveLanguage('pt');
    expect(await Persistence.loadLanguage(), 'pt');
  });
}
