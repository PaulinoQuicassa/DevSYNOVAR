import 'dart:async';

import 'package:flutter/material.dart';
import '../app_state.dart';
import '../auth/auth_service.dart';
import '../data/mock_data.dart';
import '../models/live_ticket.dart';
import '../models/my_ticket.dart';
import '../theme/app_theme.dart';
import '../ticket_navigation.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/bank_logo.dart';
import '../widgets/status_pill.dart';

/// Histórico ao vivo de todas as senhas reais do cliente, em todas as
/// localizações reais do `MockData` — substitui a leitura antiga de
/// `historyStore`, que só ganhava uma entrada quando o cliente chegava a
/// avaliar um atendimento concluído (nunca mostrava "Não Compareceu",
/// "Transferido", "Em atendimento", etc.).
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final Map<String, List<MyTicket>> _byInstitution = {};
  final List<StreamSubscription<List<MyTicket>>> _subs = [];

  @override
  void initState() {
    super.initState();
    final uid = authService.currentUser?.id;
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

  List<MyTicket> get _allTickets {
    final all = _byInstitution.values.expand((l) => l).toList();
    all.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return all;
  }

  Color _statusColor(MyTicket t) {
    switch (t.status) {
      case TicketStatus.waiting:
        return AppColors.primary;
      case TicketStatus.serving:
        return AppColors.amber;
      case TicketStatus.done:
        return AppColors.success;
      case TicketStatus.noShow:
        return AppColors.critical;
      case TicketStatus.unknown:
        return AppColors.textMuted;
    }
  }

  Color _statusBg(Color color) => color.withValues(alpha: 0.14);

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _openTicket(MyTicket t) async {
    if (!t.isActive) return;
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
    // A senha pode já não estar activa nesta app (ex.: foi retirada
    // noutra sessão) — garante que fica a ser seguida globalmente outra
    // vez ao reabrir, para os avisos continuarem a funcionar.
    if (!activeTicketStore.value.any((r) => r.ticketId == t.ref.ticketId)) {
      addActiveTicket(t.ref);
    }
    await openLiveTicketScreen(nav, t.ref, live);
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _allTickets;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Os meus atendimentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Histórico real das suas senhas — actualizado ao vivo.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        if (tickets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, color: AppColors.textMuted, size: 32),
                SizedBox(height: 10),
                Text('Ainda sem atendimentos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              ],
            ),
          )
        else
          ...tickets.map((t) {
            final color = _statusColor(t);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: t.isActive ? () => _openTicket(t) : null,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
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
                              Text(t.serviceName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Text('${_dateLabel(t.createdAt)}  ·  Senha ${t.code}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        StatusPill(label: t.statusLabel, color: color, background: _statusBg(color)),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
