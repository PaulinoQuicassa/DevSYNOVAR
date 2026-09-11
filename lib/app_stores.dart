import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/mock_data.dart';
import 'models/app_notification.dart';
import 'models/appointment.dart';
import 'models/favorite.dart';
import 'models/queue_location.dart';
import 'models/service_item.dart';
import 'supabase_client.dart';
import 'ticket_service.dart' as ticket_service;

/// App-wide stores. Held in memory for instant UI updates, e a maior parte
/// espelhada no Postgres do Supabase (`appointments`, `notifications`,
/// `user_settings`) para agendamentos/preferências sincronizarem entre
/// dispositivos da mesma conta. Each store exposes
/// `listenTo(uid)`/`stopListening()`, driven by [AuthGate] as the signed-in
/// user changes — there is nothing to show until a user is signed in.

QueueLocation? _findLocationByIds(String institutionId, String branchId) {
  for (final location in MockData.locations) {
    if (location.institutionId == institutionId && location.branchId == branchId) return location;
  }
  return null;
}

class AppointmentsStore extends ValueNotifier<List<Appointment>> {
  AppointmentsStore() : super(const []);

  RealtimeChannel? _channel;
  String? _uid;

  Future<void> _refetch() async {
    final uid = _uid;
    if (uid == null) return;
    final rows = await supabaseClient
        .from('appointments')
        .select('code, institution_id, branch_id, service, date, time')
        .eq('customer_id', uid)
        .eq('status', 'scheduled');
    final loaded = <Appointment>[];
    for (final row in rows as List) {
      final institutionId = row['institution_id'] as String;
      final branchId = row['branch_id'] as String;
      final location = _findLocationByIds(institutionId, branchId);
      if (location == null) continue;
      ServiceItem? service;
      for (final s in location.services) {
        if (s.name == row['service']) service = s;
      }
      if (service == null) continue;
      loaded.add(Appointment(
        code: row['code'] as String,
        location: location,
        service: service,
        date: DateTime.parse(row['date'] as String),
        time: row['time'] as String,
      ));
    }
    loaded.sort((a, b) => a.date.compareTo(b.date));
    value = loaded;
  }

  void listenTo(String uid) {
    _channel?.unsubscribe();
    _uid = uid;
    value = const [];
    _channel = supabaseClient
        .channel('appointments:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'appointments',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'customer_id', value: uid),
          callback: (_) => _refetch(),
        )
        // Resincroniza sempre que o canal fica `subscribed` -- primeira
        // vez e também depois de reconectar (ver nota em
        // ticket_service.dart:_watchTable).
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refetch();
        });
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _uid = null;
    value = const [];
  }

  /// Actualiza a lista logo (resposta instantânea na UI), mas espera
  /// mesmo pelo `schedule_appointment` no servidor antes de dar como
  /// concluído -- se falhar (rede, RLS, código já usado), desfaz a
  /// alteração local e propaga o erro, para quem chamou poder mostrar
  /// isso ao cliente em vez de navegar para "agendamento confirmado" com
  /// um agendamento que nunca chegou a existir no servidor.
  Future<void> add(Appointment appointment) async {
    final institutionId = appointment.location.institutionId;
    final branchId = appointment.location.branchId;
    if (institutionId == null || branchId == null) {
      value = [...value, appointment]..sort((a, b) => a.date.compareTo(b.date));
      return;
    }
    value = [...value, appointment]..sort((a, b) => a.date.compareTo(b.date));
    try {
      await ticket_service.scheduleAppointment(
        institutionId: institutionId,
        branchId: branchId,
        code: appointment.code,
        serviceName: appointment.service.name,
        date: appointment.date,
        time: appointment.time,
      );
    } catch (_) {
      value = value.where((a) => a.code != appointment.code).toList();
      rethrow;
    }
  }

  /// Mesmo raciocínio de [add]: remove logo da UI, mas se o
  /// `cancel_appointment` falhar no servidor, repõe o agendamento na
  /// lista e propaga o erro -- sem isto o cliente via "cancelado" mesmo
  /// que continuasse marcado no servidor.
  Future<void> cancel(Appointment appointment) async {
    final previous = value;
    value = value.where((a) => a.code != appointment.code).toList();
    try {
      await ticket_service.cancelAppointmentMirror(code: appointment.code);
    } catch (_) {
      value = previous;
      rethrow;
    }
  }

  Future<void> clearAll() async {
    final current = value;
    value = const [];
    for (final appointment in current) {
      await ticket_service.cancelAppointmentMirror(code: appointment.code);
    }
  }
}

/// Instituições favoritas do utilizador (secção 26 do redesign) -- tabela
/// `favorites`, mesmo padrão simples de `notifications` (DML directo via
/// RLS, sem RPC -- não há concorrência nem lógica de fila a proteger
/// numa preferência pessoal).
class FavoritesStore extends ValueNotifier<List<Favorite>> {
  FavoritesStore() : super(const []);

  RealtimeChannel? _channel;
  String? _uid;

  Future<void> _refetch() async {
    final uid = _uid;
    if (uid == null) return;
    final rows = await supabaseClient.from('favorites').select('institution_id, branch_id').eq('user_id', uid);
    value = (rows as List)
        .map((row) => Favorite(institutionId: row['institution_id'] as String, branchId: row['branch_id'] as String))
        .toList();
  }

  void listenTo(String uid) {
    _channel?.unsubscribe();
    _uid = uid;
    value = const [];
    _channel = supabaseClient
        .channel('favorites:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'favorites',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (_) => _refetch(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refetch();
        });
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _uid = null;
    value = const [];
  }

  bool isFavorite(String institutionId, String branchId) =>
      value.any((f) => f.institutionId == institutionId && f.branchId == branchId);

  Future<void> toggle(String institutionId, String branchId) async {
    final uid = _uid;
    if (uid == null) return;
    if (isFavorite(institutionId, branchId)) {
      value = value.where((f) => !(f.institutionId == institutionId && f.branchId == branchId)).toList();
      await supabaseClient
          .from('favorites')
          .delete()
          .eq('user_id', uid)
          .eq('institution_id', institutionId)
          .eq('branch_id', branchId);
    } else {
      value = [...value, Favorite(institutionId: institutionId, branchId: branchId)];
      await supabaseClient.from('favorites').insert({
        'user_id': uid,
        'institution_id': institutionId,
        'branch_id': branchId,
      });
    }
  }
}

/// Notificações recebidas pelo cliente (ex.: "É a sua vez!") — grava-se
/// sempre que [GlobalQueueAlerts] dispara um aviso, mesmo com o som
/// desligado nas definições (só o som/banner é que fica condicionado a
/// essa definição, o registo em si não). Alimenta a contagem real do
/// sino no `HomeScreen`.
class NotificationsStore extends ValueNotifier<List<AppNotification>> {
  NotificationsStore() : super(const []);

  RealtimeChannel? _channel;
  String? _uid;

  Future<void> _refetch() async {
    final uid = _uid;
    if (uid == null) return;
    final rows = await supabaseClient
        .from('notifications')
        .select('id, title, subtitle, created_at, read')
        .eq('user_id', uid)
        .order('created_at', ascending: false);
    value = (rows as List)
        .map((row) => AppNotification(
              id: row['id'] as String,
              title: row['title'] as String? ?? '',
              subtitle: row['subtitle'] as String? ?? '',
              createdAt: row['created_at'] == null ? null : DateTime.parse(row['created_at'] as String).toLocal(),
              read: row['read'] as bool? ?? false,
            ))
        .toList();
  }

  void listenTo(String uid) {
    _channel?.unsubscribe();
    _uid = uid;
    value = const [];
    _channel = supabaseClient
        .channel('notifications:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (_) => _refetch(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refetch();
        });
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _uid = null;
    value = const [];
  }

  void add({required String title, required String subtitle}) {
    final uid = _uid;
    if (uid == null) return;
    unawaited(supabaseClient.from('notifications').insert({
      'user_id': uid,
      'title': title,
      'subtitle': subtitle,
      'read': false,
    }));
  }

  Future<void> markAllRead() async {
    final uid = _uid;
    if (uid == null || value.every((n) => n.read)) return;
    await supabaseClient.from('notifications').update({'read': true}).eq('user_id', uid).eq('read', false);
  }
}

Future<void> _ensureSettingsRow(String uid) {
  return supabaseClient.from('user_settings').upsert({'user_id': uid}, onConflict: 'user_id', ignoreDuplicates: true);
}

class NotificationSettings extends ChangeNotifier {
  bool queueAlerts = true;
  bool appointmentReminders = true;
  bool promotions = false;
  bool whatsapp = true;

  RealtimeChannel? _channel;
  String? _uid;

  Future<void> _refetch() async {
    final uid = _uid;
    if (uid == null) return;
    final row = await supabaseClient
        .from('user_settings')
        .select('queue_alerts, appointment_reminders, promotions, whatsapp')
        .eq('user_id', uid)
        .maybeSingle();
    if (row == null) return;
    queueAlerts = row['queue_alerts'] as bool? ?? queueAlerts;
    appointmentReminders = row['appointment_reminders'] as bool? ?? appointmentReminders;
    promotions = row['promotions'] as bool? ?? promotions;
    whatsapp = row['whatsapp'] as bool? ?? whatsapp;
    notifyListeners();
  }

  Future<void> listenTo(String uid) async {
    _channel?.unsubscribe();
    _uid = uid;
    await _ensureSettingsRow(uid);
    await _refetch();
    _channel = supabaseClient
        .channel('user_settings:notif:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_settings',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (_) => _refetch(),
        )
        // Resincroniza também depois de reconectar (ver nota em
        // ticket_service.dart:_watchTable) -- a linha já existe a esta
        // altura, não é preciso repetir `_ensureSettingsRow`.
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refetch();
        });
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
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
    final column = switch (key) {
      'queueAlerts' => 'queue_alerts',
      'appointmentReminders' => 'appointment_reminders',
      'promotions' => 'promotions',
      'whatsapp' => 'whatsapp',
      _ => key,
    };
    final newValue = switch (key) {
      'queueAlerts' => queueAlerts,
      'appointmentReminders' => appointmentReminders,
      'promotions' => promotions,
      'whatsapp' => whatsapp,
      _ => true,
    };
    unawaited(supabaseClient.from('user_settings').update({column: newValue}).eq('user_id', uid));
  }
}

/// 'pt' é o único idioma totalmente suportado hoje; mantido como store
/// próprio para o ecrã de Definições mostrar e mudar uma seleção real,
/// sincronizada entre dispositivos da mesma conta (mesma linha
/// `user_settings` do [NotificationSettings], coluna `language`).
class AppLanguageController extends ValueNotifier<String> {
  AppLanguageController() : super('pt');

  RealtimeChannel? _channel;
  String? _uid;

  Future<void> _refetch() async {
    final uid = _uid;
    if (uid == null) return;
    final row = await supabaseClient.from('user_settings').select('language').eq('user_id', uid).maybeSingle();
    final lang = row?['language'] as String?;
    if (lang != null) value = lang;
  }

  Future<void> listenTo(String uid) async {
    _channel?.unsubscribe();
    _uid = uid;
    await _ensureSettingsRow(uid);
    await _refetch();
    _channel = supabaseClient
        .channel('user_settings:lang:$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'user_settings',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: uid),
          callback: (_) => _refetch(),
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) _refetch();
        });
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _uid = null;
    value = 'pt';
  }

  void setLanguage(String lang) {
    final uid = _uid;
    value = lang;
    if (uid == null) return;
    unawaited(supabaseClient.from('user_settings').update({'language': lang}).eq('user_id', uid));
  }
}

final appointmentsStore = AppointmentsStore();
final favoritesStore = FavoritesStore();
final notificationsStore = NotificationsStore();
final notificationSettings = NotificationSettings();
final appLanguageController = AppLanguageController();

/// Liga todos os stores aos dados da conta `uid` — chamado pelo [AuthGate]
/// quando alguém entra. Cada store passa a espelhar o Postgres em tempo
/// real. Não chamado para visitantes (modo convidado, Fila Certa 2.0) --
/// sem conta não há nenhuma destas listas a sincronizar.
void startUserDataSync(String uid) {
  appointmentsStore.listenTo(uid);
  favoritesStore.listenTo(uid);
  notificationsStore.listenTo(uid);
  notificationSettings.listenTo(uid);
  appLanguageController.listenTo(uid);
}

/// Desliga todos os stores da conta anterior — chamado pelo [AuthGate]
/// quando alguém termina sessão, para não vazar dados de uma conta para a
/// próxima que entrar no mesmo aparelho.
void stopUserDataSync() {
  appointmentsStore.stopListening();
  favoritesStore.stopListening();
  notificationsStore.stopListening();
  notificationSettings.stopListening();
  appLanguageController.stopListening();
}
