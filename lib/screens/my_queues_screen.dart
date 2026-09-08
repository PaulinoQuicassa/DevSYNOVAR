import 'dart:async';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../auth/require_auth.dart';
import '../data/mock_data.dart';
import '../models/appointment.dart';
import '../models/live_ticket.dart';
import '../models/my_ticket.dart';
import '../models/queue_display_status.dart';
import '../theme/app_theme.dart';
import '../ticket_navigation.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/bank_logo.dart';
import '../widgets/gradient_button.dart';
import '../widgets/status_pill.dart';
import 'appointment_detail_screen.dart';
import 'choose_location_screen.dart';
import 'schedule_datetime_screen.dart' show formatShortDate;

/// "Minhas filas" (Fila Certa 2.0) -- o que está activo AGORA: senhas em
/// espera/atendimento + agendamentos futuros. O histórico (concluído,
/// cancelado, não compareceu) vive à parte em `my_appointments_screen.dart`
/// ("Histórico"), para esta lista nunca ficar poluída com o que já
/// terminou -- exactamente a separação pedida na secção 28 do redesign
/// ("privilegiar... fila actual" antes de histórico).
class MyQueuesScreen extends StatefulWidget {
  const MyQueuesScreen({super.key});

  @override
  State<MyQueuesScreen> createState() => _MyQueuesScreenState();
}

class _MyQueuesScreenState extends State<MyQueuesScreen> {
  final Map<String, List<MyTicket>> _byInstitution = {};
  final List<StreamSubscription<List<MyTicket>>> _subs = [];
  String? _subscribedUid;

  @override
  void initState() {
    super.initState();
    _resubscribeIfNeeded();
  }

  void _resubscribeIfNeeded() {
    final uid = authService.currentUser?.id;
    if (uid == _subscribedUid) return;
    for (final sub in _subs) {
      sub.cancel();
    }
    _subs.clear();
    _byInstitution.clear();
    _subscribedUid = uid;
    if (uid == null) return;
    for (final location in MockData.locations) {
      if (location.institutionId == null || location.branchId == null) continue;
      _subs.add(ticket_service.subscribeMyTickets(location, uid).listen((tickets) {
        if (!mounted) return;
        setState(() => _byInstitution[location.institutionId!] = tickets);
      }));
    }
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  List<MyTicket> get _activeTickets {
    final all = _byInstitution.values.expand((l) => l).where((t) => t.isActive).toList();
    all.sort((a, b) => (a.createdAt ?? DateTime(0)).compareTo(b.createdAt ?? DateTime(0)));
    return all;
  }

  Future<void> _openTicket(MyTicket t) async {
    final nav = Navigator.of(context, rootNavigator: true);
    final live = LiveTicket(
      code: t.code,
      service: t.serviceName,
      status: t.status,
      counterId: t.counterId,
      createdAt: t.createdAt,
      calledAt: t.calledAt,
      noShowReason: t.noShowReason,
    );
    if (!activeTicketStore.value.any((r) => r.ticketId == t.ref.ticketId)) {
      addActiveTicket(t.ref);
    }
    await openLiveTicketScreen(nav, t.ref, live);
  }

  Future<void> _startQueueing(BuildContext context) async {
    final ok = await requireAuth(context, reason: 'Precisa de uma conta para guardar o seu lugar na fila e avisá-lo quando for a sua vez.');
    if (!ok || !context.mounted) return;
    goToRootTab(context, 1); // Explorar
  }

  void _newAppointment(BuildContext context) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => const ChooseLocationScreen(isScheduling: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    _resubscribeIfNeeded();
    final signedIn = authService.currentUser != null;
    final tickets = _activeTickets;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Minhas filas', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        const Text('O que está a acontecer agora — actualizado ao vivo.', style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),
        if (!signedIn) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.heroGradient, borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ainda não entrou em nenhuma fila', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15.5)),
                const SizedBox(height: 6),
                const Text(
                  'Explore os serviços perto de si e entre numa fila — só lhe pedimos uma conta nesse momento.',
                  style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                ),
                const SizedBox(height: 16),
                OutlineButton(
                  label: 'Explorar serviços',
                  icon: Icons.explore_outlined,
                  color: Colors.white,
                  onTap: () => _startQueueing(context),
                ),
              ],
            ),
          ),
        ] else ...[
          if (tickets.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 32),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  const Icon(Icons.confirmation_number_outlined, color: AppColors.textMuted, size: 32),
                  const SizedBox(height: 10),
                  const Text('Sem filas activas neste momento', style: AppTextStyles.bodyStrong),
                  const SizedBox(height: 12),
                  TextButton(onPressed: () => goToRootTab(context, 1), child: const Text('Explorar serviços')),
                ],
              ),
            )
          else
            ...tickets.map((t) {
              final display = queueDisplayStatusFrom(status: t.status, wasTransferred: t.wasTransferred, noShowReason: t.noShowReason);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    onTap: () => _openTicket(t),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BankLogo(monogram: t.location.monogram, color: t.location.brandColor, size: 44),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.location.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.25)),
                                const SizedBox(height: 2),
                                Text(t.serviceName, style: AppTextStyles.bodySmall),
                                const SizedBox(height: 6),
                                Text('Senha ${t.code}', style: AppTextStyles.caption),
                              ],
                            ),
                          ),
                          StatusPill(label: display.label, color: display.color, background: display.background, icon: display.icon),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Próximos agendamentos', style: AppTextStyles.h3),
              TextButton(onPressed: () => _newAppointment(context), child: const Text('Novo')),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<List<Appointment>>(
            valueListenable: appointmentsStore,
            builder: (context, appointments, _) {
              if (appointments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text('Sem agendamentos marcados', style: AppTextStyles.bodySmall),
                );
              }
              return Column(
                children: appointments
                    .map((a) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Material(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => AppointmentDetailScreen(appointment: a)),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  children: [
                                    BankLogo(monogram: a.location.monogram, color: a.location.brandColor, size: 38),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(a.location.name, style: AppTextStyles.bodyStrong),
                                          Text('${a.service.name} · ${formatShortDate(a.date)} ${a.time}', style: AppTextStyles.bodySmall),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        ],
      ],
    );
  }
}
