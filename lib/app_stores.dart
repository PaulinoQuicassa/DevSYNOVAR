import 'dart:async';

import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'models/appointment.dart';
import 'models/visit.dart';
import 'persistence.dart';

/// App-wide stores. Held in memory for instant UI updates, and mirrored to
/// on-device storage (`persistence.dart`) so agendamentos/histórico/
/// preferências survive closing and reopening the app — there is still no
/// backend, so nothing syncs across devices.

List<Appointment> _seedAppointments() => [
      Appointment(
        code: 'AG-1042',
        location: MockData.locations[2],
        service: MockData.bankServices[3],
        date: DateTime(2026, 8, 22, 10, 30),
        time: '10:30',
      ),
      Appointment(
        code: 'AG-1077',
        location: MockData.locations[3],
        service: MockData.bankServices[2],
        date: DateTime(2026, 8, 25, 14, 0),
        time: '14:00',
      ),
    ];

class AppointmentsStore extends ValueNotifier<List<Appointment>> {
  AppointmentsStore() : super(_seedAppointments());

  /// Loads any previously-saved appointments from disk, replacing the seed
  /// data if found. Call once, before the first frame (see `main.dart`).
  Future<void> hydrate() async {
    final loaded = await Persistence.loadAppointments();
    if (loaded != null) value = loaded;
  }

  void add(Appointment appointment) {
    value = [...value, appointment]..sort((a, b) => a.date.compareTo(b.date));
    unawaited(Persistence.saveAppointments(value));
  }

  void cancel(Appointment appointment) {
    value = value.where((a) => a.code != appointment.code).toList();
    unawaited(Persistence.saveAppointments(value));
  }

  void reset() {
    value = _seedAppointments();
    unawaited(Persistence.saveAppointments(value));
  }
}

const _seedHistory = <Visit>[
  Visit(
    bank: 'Banco de Poupança e Crédito (BPC)',
    monogram: 'BPC',
    color: Color(0xFF1D3F91),
    service: 'Atendimento Balcão',
    date: 'Hoje, 09:41',
    ticket: 'A023',
    status: VisitStatus.completed,
    rating: 5,
  ),
  Visit(
    bank: 'Banco BFA',
    monogram: 'BFA',
    color: Color(0xFFE8622C),
    service: 'Depósitos e Levantamentos',
    date: 'Ontem, 15:12',
    ticket: 'B104',
    status: VisitStatus.completed,
    rating: 4,
  ),
  Visit(
    bank: 'SIAC — Serviço Integrado de Atendimento ao Cidadão',
    monogram: 'SIAC',
    color: Color(0xFF2E7CB8),
    service: 'Bilhete de Identidade',
    date: '14 Ago, 11:05',
    ticket: 'C051',
    status: VisitStatus.missed,
  ),
];

class HistoryStore extends ValueNotifier<List<Visit>> {
  HistoryStore() : super(_seedHistory);

  Future<void> hydrate() async {
    final loaded = await Persistence.loadHistory();
    if (loaded != null) value = loaded;
  }

  void addCompleted({required Visit visit}) {
    value = [visit, ...value];
    unawaited(Persistence.saveHistory(value));
  }

  void reset() {
    value = _seedHistory;
    unawaited(Persistence.saveHistory(value));
  }
}

class NotificationSettings extends ChangeNotifier {
  bool queueAlerts = true;
  bool appointmentReminders = true;
  bool promotions = false;
  bool whatsapp = true;

  Future<void> hydrate() async {
    final loaded = await Persistence.loadNotificationSettings();
    if (loaded == null) return;
    queueAlerts = loaded['queueAlerts'] ?? queueAlerts;
    appointmentReminders = loaded['appointmentReminders'] ?? appointmentReminders;
    promotions = loaded['promotions'] ?? promotions;
    whatsapp = loaded['whatsapp'] ?? whatsapp;
    notifyListeners();
  }

  void toggle(String key) {
    switch (key) {
      case 'queueAlerts':
        queueAlerts = !queueAlerts;
      case 'appointmentReminders':
        appointmentReminders = !appointmentReminders;
      case 'promotions':
        promotions = !promotions;
      case 'whatsapp':
        whatsapp = !whatsapp;
    }
    notifyListeners();
    unawaited(Persistence.saveNotificationSettings({
      'queueAlerts': queueAlerts,
      'appointmentReminders': appointmentReminders,
      'promotions': promotions,
      'whatsapp': whatsapp,
    }));
  }
}

final appointmentsStore = AppointmentsStore();
final historyStore = HistoryStore();
final notificationSettings = NotificationSettings();

/// 'pt' is the only fully supported language today; kept as a [ValueNotifier]
/// so the Settings screen can show and change a real, current selection.
final appLanguageController = ValueNotifier<String>('pt');

/// Loads every persisted store from disk. Call once, before the first frame
/// (see `main.dart`) — the seed/default values above are already in place
/// synchronously, so the UI never has nothing to show while this runs.
Future<void> hydrateAllStores() async {
  await Future.wait([
    appointmentsStore.hydrate(),
    historyStore.hydrate(),
    notificationSettings.hydrate(),
    Persistence.loadLanguage().then((lang) {
      if (lang != null) appLanguageController.value = lang;
    }),
  ]);
  appLanguageController.addListener(() {
    unawaited(Persistence.saveLanguage(appLanguageController.value));
  });
}
