import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'data/mock_data.dart';
import 'models/appointment.dart';
import 'models/queue_location.dart';
import 'models/service_item.dart';
import 'models/visit.dart';
import 'ticket_service.dart' as ticket_service;

/// App-wide stores. Held in memory for instant UI updates, and mirrored to
/// Firestore under `users/{uid}/...` so agendamentos/histórico/preferências
/// sincronizam entre dispositivos da mesma conta. Each store exposes
/// `listenTo(uid)`/`stopListening()`, driven by [AuthGate] as the signed-in
/// user changes — there is nothing to show until a user is signed in.

/// Mutable (not `final`) so tests can point every store at a
/// `FakeFirebaseFirestore` (`fake_cloud_firestore`) before pumping widgets.
FirebaseFirestore firestoreInstance = FirebaseFirestore.instance;

QueueLocation? _findLocation(String monogram) {
  for (final location in MockData.locations) {
    if (location.monogram == monogram) return location;
  }
  return null;
}

ServiceItem? _findService(QueueLocation location, String name) {
  for (final service in location.services) {
    if (service.name == name) return service;
  }
  return null;
}

class AppointmentsStore extends ValueNotifier<List<Appointment>> {
  AppointmentsStore() : super(const []);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      firestoreInstance.collection('users').doc(uid).collection('appointments');

  void listenTo(String uid) {
    _sub?.cancel();
    _uid = uid;
    value = const [];
    _sub = _collection(uid).snapshots().listen((snapshot) {
      final loaded = <Appointment>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final location = _findLocation(data['locationMonogram'] as String? ?? '');
        if (location == null) continue;
        final service = _findService(location, data['serviceName'] as String? ?? '');
        if (service == null) continue;
        final timestamp = data['date'] as Timestamp?;
        if (timestamp == null) continue;
        loaded.add(Appointment(
          code: doc.id,
          location: location,
          service: service,
          date: timestamp.toDate(),
          time: data['time'] as String? ?? '',
        ));
      }
      loaded.sort((a, b) => a.date.compareTo(b.date));
      value = loaded;
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    value = const [];
  }

  void add(Appointment appointment) {
    final uid = _uid;
    if (uid == null) return;
    value = [...value, appointment]..sort((a, b) => a.date.compareTo(b.date));
    unawaited(_collection(uid).doc(appointment.code).set({
      'locationMonogram': appointment.location.monogram,
      'serviceName': appointment.service.name,
      'date': Timestamp.fromDate(appointment.date),
      'time': appointment.time,
    }));
    final institutionId = appointment.location.institutionId;
    final branchId = appointment.location.branchId;
    if (institutionId != null && branchId != null) {
      unawaited(ticket_service.scheduleAppointment(
        institutionId: institutionId,
        branchId: branchId,
        code: appointment.code,
        customerUid: uid,
        serviceName: appointment.service.name,
        date: appointment.date,
        time: appointment.time,
      ));
    }
  }

  void cancel(Appointment appointment) {
    final uid = _uid;
    if (uid == null) return;
    value = value.where((a) => a.code != appointment.code).toList();
    unawaited(_collection(uid).doc(appointment.code).delete());
    final institutionId = appointment.location.institutionId;
    final branchId = appointment.location.branchId;
    if (institutionId != null && branchId != null) {
      unawaited(ticket_service.cancelAppointmentMirror(
        institutionId: institutionId,
        branchId: branchId,
        code: appointment.code,
      ));
    }
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    final snapshot = await _collection(uid).get();
    final batch = firestoreInstance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class HistoryStore extends ValueNotifier<List<Visit>> {
  HistoryStore() : super(const []);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      firestoreInstance.collection('users').doc(uid).collection('history');

  void listenTo(String uid) {
    _sub?.cancel();
    _uid = uid;
    value = const [];
    _sub = _collection(uid).orderBy('createdAt', descending: true).snapshots().listen((snapshot) {
      value = snapshot.docs.map((doc) {
        final data = doc.data();
        final monogram = data['monogram'] as String? ?? '';
        final location = _findLocation(monogram);
        return Visit(
          bank: data['bank'] as String? ?? '',
          monogram: monogram,
          color: location?.brandColor ?? const Color(0xFF64748B),
          service: data['service'] as String? ?? '',
          date: data['date'] as String? ?? '',
          ticket: data['ticket'] as String? ?? '',
          status: (data['status'] as String?) == 'missed' ? VisitStatus.missed : VisitStatus.completed,
          rating: data['rating'] as int?,
        );
      }).toList();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    value = const [];
  }

  void addCompleted({required Visit visit}) {
    final uid = _uid;
    if (uid == null) return;
    value = [visit, ...value];
    unawaited(_collection(uid).add({
      'bank': visit.bank,
      'monogram': visit.monogram,
      'service': visit.service,
      'date': visit.date,
      'ticket': visit.ticket,
      'status': visit.status == VisitStatus.missed ? 'missed' : 'completed',
      'rating': visit.rating,
      'createdAt': FieldValue.serverTimestamp(),
    }));
  }

  Future<void> clearAll() async {
    final uid = _uid;
    if (uid == null) return;
    final snapshot = await _collection(uid).get();
    final batch = firestoreInstance.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

class NotificationSettings extends ChangeNotifier {
  bool queueAlerts = true;
  bool appointmentReminders = true;
  bool promotions = false;
  bool whatsapp = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      firestoreInstance.collection('users').doc(uid).collection('settings').doc('preferences');

  void listenTo(String uid) {
    _sub?.cancel();
    _uid = uid;
    _sub = _doc(uid).snapshots().listen((snapshot) {
      final data = snapshot.data();
      if (data == null) return;
      queueAlerts = data['queueAlerts'] as bool? ?? queueAlerts;
      appointmentReminders = data['appointmentReminders'] as bool? ?? appointmentReminders;
      promotions = data['promotions'] as bool? ?? promotions;
      whatsapp = data['whatsapp'] as bool? ?? whatsapp;
      notifyListeners();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    queueAlerts = true;
    appointmentReminders = true;
    promotions = false;
    whatsapp = true;
  }

  void toggle(String key) {
    final uid = _uid;
    if (uid == null) return;
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
    unawaited(_doc(uid).set({
      'queueAlerts': queueAlerts,
      'appointmentReminders': appointmentReminders,
      'promotions': promotions,
      'whatsapp': whatsapp,
    }, SetOptions(merge: true)));
  }
}

/// 'pt' é o único idioma totalmente suportado hoje; mantido como store
/// próprio para o ecrã de Definições mostrar e mudar uma seleção real,
/// sincronizada entre dispositivos da mesma conta.
class AppLanguageController extends ValueNotifier<String> {
  AppLanguageController() : super('pt');

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  String? _uid;

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      firestoreInstance.collection('users').doc(uid).collection('settings').doc('preferences');

  void listenTo(String uid) {
    _sub?.cancel();
    _uid = uid;
    _sub = _doc(uid).snapshots().listen((snapshot) {
      final lang = snapshot.data()?['language'] as String?;
      if (lang != null) value = lang;
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _uid = null;
    value = 'pt';
  }

  void setLanguage(String lang) {
    final uid = _uid;
    value = lang;
    if (uid == null) return;
    unawaited(_doc(uid).set({'language': lang}, SetOptions(merge: true)));
  }
}

final appointmentsStore = AppointmentsStore();
final historyStore = HistoryStore();
final notificationSettings = NotificationSettings();
final appLanguageController = AppLanguageController();

/// Liga todos os stores aos dados da conta `uid` — chamado pelo [AuthGate]
/// quando alguém entra. Cada store passa a espelhar Firestore em tempo real.
void startUserDataSync(String uid) {
  appointmentsStore.listenTo(uid);
  historyStore.listenTo(uid);
  notificationSettings.listenTo(uid);
  appLanguageController.listenTo(uid);
}

/// Desliga todos os stores da conta anterior — chamado pelo [AuthGate]
/// quando alguém termina sessão, para não vazar dados de uma conta para a
/// próxima que entrar no mesmo aparelho.
void stopUserDataSync() {
  appointmentsStore.stopListening();
  historyStore.stopListening();
  notificationSettings.stopListening();
  appLanguageController.stopListening();
}
