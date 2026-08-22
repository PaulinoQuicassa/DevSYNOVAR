import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/mock_data.dart';
import 'models/appointment.dart';
import 'models/queue_location.dart';
import 'models/service_item.dart';
import 'models/visit.dart';

/// Local, on-device persistence (SharedPreferences) for the in-memory stores
/// in `app_stores.dart`. There is still no backend — this only survives
/// closing and reopening the app on the same device, not across devices.
///
/// Appointments/history are stored as small JSON snapshots keyed to a mock
/// location's `monogram` (and, for appointments, a service name within that
/// location) so they can be resolved back against the current
/// [MockData] catalogue on load. If a referenced location/service ever
/// disappears from the catalogue, that one record is silently dropped
/// instead of crashing the app on startup.
class Persistence {
  Persistence._();

  static const _appointmentsKey = 'fila_certa.appointments.v1';
  static const _historyKey = 'fila_certa.history.v1';
  static const _notificationsKey = 'fila_certa.notifications.v1';
  static const _languageKey = 'fila_certa.language.v1';

  static QueueLocation? _findLocation(String monogram) {
    for (final loc in MockData.locations) {
      if (loc.monogram == monogram) return loc;
    }
    return null;
  }

  static ServiceItem? _findService(QueueLocation location, String name) {
    for (final s in location.services) {
      if (s.name == name) return s;
    }
    return null;
  }

  // --- Appointments ---------------------------------------------------

  static Future<void> saveAppointments(List<Appointment> appointments) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(appointments
        .map((a) => {
              'code': a.code,
              'locationMonogram': a.location.monogram,
              'serviceName': a.service.name,
              'date': a.date.toIso8601String(),
              'time': a.time,
            })
        .toList());
    await prefs.setString(_appointmentsKey, encoded);
  }

  static Future<List<Appointment>?> loadAppointments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_appointmentsKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      final result = <Appointment>[];
      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final location = _findLocation(map['locationMonogram'] as String);
        if (location == null) continue;
        final service = _findService(location, map['serviceName'] as String);
        if (service == null) continue;
        result.add(Appointment(
          code: map['code'] as String,
          location: location,
          service: service,
          date: DateTime.parse(map['date'] as String),
          time: map['time'] as String,
        ));
      }
      return result;
    } catch (_) {
      // Corrupt or incompatible data from an older app version — ignore it
      // rather than crashing startup; the caller falls back to the seed data.
      return null;
    }
  }

  // --- Visit history ----------------------------------------------------

  static Future<void> saveHistory(List<Visit> history) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(history
        .map((v) => {
              'bank': v.bank,
              'monogram': v.monogram,
              'service': v.service,
              'date': v.date,
              'ticket': v.ticket,
              'status': v.status.name,
              'rating': v.rating,
            })
        .toList());
    await prefs.setString(_historyKey, encoded);
  }

  static Future<List<Visit>?> loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return null;
    try {
      final list = jsonDecode(raw) as List;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        final monogram = map['monogram'] as String;
        final knownLocation = _findLocation(monogram);
        return Visit(
          bank: map['bank'] as String,
          monogram: monogram,
          color: knownLocation?.brandColor ?? const Color(0xFF64748B),
          service: map['service'] as String,
          date: map['date'] as String,
          ticket: map['ticket'] as String,
          status: VisitStatus.values.byName(map['status'] as String),
          rating: map['rating'] as int?,
        );
      }).toList();
    } catch (_) {
      return null;
    }
  }

  // --- Notification preferences -----------------------------------------

  static Future<void> saveNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationsKey, jsonEncode(settings));
  }

  static Future<Map<String, bool>?> loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notificationsKey);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map((key, value) => MapEntry(key, value as bool));
    } catch (_) {
      return null;
    }
  }

  // --- Language -----------------------------------------------------------

  static Future<void> saveLanguage(String language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language);
  }

  static Future<String?> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
}
