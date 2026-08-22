import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'models/appointment.dart';
import 'models/visit.dart';

/// In-memory (non-persisted) app-wide stores. There is no backend, so state
/// resets on a fresh app launch — but within a session, creating/cancelling
/// an appointment or finishing a visit updates every screen that reads it.

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

  void add(Appointment appointment) {
    value = [...value, appointment]..sort((a, b) => a.date.compareTo(b.date));
  }

  void cancel(Appointment appointment) {
    value = value.where((a) => a.code != appointment.code).toList();
  }

  void reset() => value = _seedAppointments();
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
    bank: 'SIAC — Centro de Atendimento',
    monogram: 'SIAC',
    color: Color(0xFF2E7CB8),
    service: 'Serviços ao Cidadão',
    date: '14 Ago, 11:05',
    ticket: 'C051',
    status: VisitStatus.missed,
  ),
];

class HistoryStore extends ValueNotifier<List<Visit>> {
  HistoryStore() : super(_seedHistory);

  void addCompleted({required Visit visit}) {
    value = [visit, ...value];
  }

  void reset() => value = _seedHistory;
}

class NotificationSettings extends ChangeNotifier {
  bool queueAlerts = true;
  bool appointmentReminders = true;
  bool promotions = false;
  bool whatsapp = true;

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
  }
}

final appointmentsStore = AppointmentsStore();
final historyStore = HistoryStore();
final notificationSettings = NotificationSettings();

/// 'pt' is the only fully supported language today; kept as a [ValueNotifier]
/// so the Settings screen can show and change a real, current selection.
final appLanguageController = ValueNotifier<String>('pt');
