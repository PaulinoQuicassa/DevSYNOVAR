import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_service.dart';
import '../data/mock_data.dart';
import '../models/my_ticket.dart';
import '../models/queue_display_status.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/bank_logo.dart';
import '../widgets/status_pill.dart';

/// "Histórico" (Fila Certa 2.0, secção 25 do redesign) -- só o que já
/// terminou (concluído, cancelado, não compareceu); o que está activo
/// agora vive à parte em `my_queues_screen.dart` ("Minhas filas"), para
/// esta lista nunca se misturar com uma fila em curso. Alimentado ao
/// vivo pelas mesmas senhas reais do cliente (`ticket_service.subscribeMyTickets`).
class MyAppointmentsScreen extends StatefulWidget {
  const MyAppointmentsScreen({super.key});

  @override
  State<MyAppointmentsScreen> createState() => _MyAppointmentsScreenState();
}

class _MyAppointmentsScreenState extends State<MyAppointmentsScreen> {
  final Map<String, List<MyTicket>> _byInstitution = {};
  final List<StreamSubscription<List<MyTicket>>> _subs = [];
  StreamSubscription<User?>? _authSub;
  String? _subscribedUid;

  @override
  void initState() {
    super.initState();
    // Fila Certa 2.0 (modo convidado): este ecrã pode ser construído uma
    // única vez pelo `IndexedStack` do RootShell logo no arranque, ainda
    // sem sessão -- sem isto, um utilizador que entrasse na conta a meio
    // da utilização nunca veria o histórico aparecer sem reiniciar a app.
    _resubscribeIfNeeded();
    _authSub = authService.userChanges.listen((_) => _resubscribeIfNeeded());
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
    if (uid == null) {
      if (mounted) setState(() {});
      return;
    }
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
    _authSub?.cancel();
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  List<MyTicket> get _pastTickets {
    final all = _byInstitution.values.expand((l) => l).where((t) => !t.isActive).toList();
    all.sort((a, b) => (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
    return all;
  }

  String _dateLabel(DateTime? dt) {
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tickets = _pastTickets;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Histórico', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        const Text('Os seus atendimentos anteriores.', style: AppTextStyles.bodySmall),
        const SizedBox(height: 20),
        if (tickets.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.history, color: AppColors.textMuted, size: 32),
                SizedBox(height: 10),
                Text('Ainda sem atendimentos concluídos', style: AppTextStyles.bodyStrong),
              ],
            ),
          )
        else
          ...tickets.map((t) {
            final display = queueDisplayStatusFrom(status: t.status, wasTransferred: t.wasTransferred, noShowReason: t.noShowReason);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
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
                          Text('${_dateLabel(t.createdAt)}  ·  Senha ${t.code}', style: AppTextStyles.caption),
                        ],
                      ),
                    ),
                    StatusPill(label: display.label, color: display.color, background: display.background, icon: display.icon),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
