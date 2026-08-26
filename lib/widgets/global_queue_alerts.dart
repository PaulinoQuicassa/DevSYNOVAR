import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../data/mock_data.dart';
import '../models/live_ticket.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../screens/almost_screen.dart';
import '../screens/called_screen.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;

/// Watches every ref in [activeTicketStore] for the whole authenticated
/// session (see `auth_gate.dart`, wraps [RootShell]) so two important
/// moments — "serás o próximo" and "é a sua vez" — still alert the
/// customer with sound even when they've wandered off to another
/// bottom-nav tab, where the queue-flow screens (`QueueScreen`/
/// `AlmostScreen`) and their own Firestore subscriptions no longer exist
/// (`goToRootTab` pops them off the navigator entirely) — including when
/// that happened because the customer went back to pull a *second*
/// ticket for a different service while the first was still waiting.
///
/// Tracks one independent watch per ticket (keyed by `ticketId`), never
/// just the most recent one — a customer can be waiting on more than one
/// service at once and every one of them must keep alerting.
class GlobalQueueAlerts extends StatefulWidget {
  final Widget child;

  const GlobalQueueAlerts({super.key, required this.child});

  @override
  State<GlobalQueueAlerts> createState() => _GlobalQueueAlertsState();
}

class _TicketWatch {
  final LiveTicketRef ref;
  TicketStatus? lastStatus;
  bool announcedNext = false;
  LiveTicket? lastTicket;
  StreamSubscription<LiveTicket?>? ticketSub;
  StreamSubscription<int>? aheadSub;

  _TicketWatch(this.ref);

  void cancel() {
    ticketSub?.cancel();
    aheadSub?.cancel();
  }
}

class _GlobalQueueAlertsState extends State<GlobalQueueAlerts> {
  final Map<String, _TicketWatch> _watches = {};

  @override
  void initState() {
    super.initState();
    activeTicketStore.addListener(_onRefsChanged);
    _onRefsChanged();
  }

  @override
  void dispose() {
    activeTicketStore.removeListener(_onRefsChanged);
    for (final watch in _watches.values) {
      watch.cancel();
    }
    super.dispose();
  }

  void _onRefsChanged() {
    final refs = activeTicketStore.value;
    final currentIds = refs.map((r) => r.ticketId).toSet();

    // Pára de seguir senhas que saíram da lista (concluídas/canceladas).
    _watches.removeWhere((id, watch) {
      if (currentIds.contains(id)) return false;
      watch.cancel();
      return true;
    });

    // Começa a seguir senhas novas.
    for (final ref in refs) {
      if (_watches.containsKey(ref.ticketId)) continue;
      final watch = _TicketWatch(ref);
      _watches[ref.ticketId] = watch;
      watch.ticketSub = ticket_service.subscribeTicket(ref).listen((ticket) => _onTicket(watch, ticket));
    }
  }

  void _onTicket(_TicketWatch watch, LiveTicket? ticket) {
    if (ticket == null) return;
    watch.lastTicket = ticket;

    if (watch.aheadSub == null && ticket.createdAt != null) {
      watch.aheadSub = ticket_service.subscribeWaitingAhead(watch.ref, ticket.createdAt!).listen((count) {
        _onAhead(watch, count);
      });
    }

    if (ticket.status == TicketStatus.serving && watch.lastStatus != TicketStatus.serving) {
      _showAlert(watch, 'É a sua vez!', '${ticket.service} — dirija-se ao balcão indicado.');
    }

    if (ticket.status == TicketStatus.done || ticket.status == TicketStatus.noShow) {
      removeActiveTicket(watch.ref.ticketId);
    }

    watch.lastStatus = ticket.status;
  }

  void _onAhead(_TicketWatch watch, int ahead) {
    if (ahead == 0 && !watch.announcedNext && watch.lastStatus == TicketStatus.waiting) {
      watch.announcedNext = true;
      final serviceName = watch.lastTicket?.service ?? '';
      _showAlert(watch, 'Serás o próximo!', '$serviceName — prepare-se, a sua vez está a chegar.');
    }
  }

  void _showAlert(_TicketWatch watch, String title, String subtitle) {
    if (!notificationSettings.queueAlerts) return;
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _GlobalAlertBanner(
        title: title,
        subtitle: subtitle,
        onTap: () {
          if (entry.mounted) entry.remove();
          _openTicket(watch);
        },
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 6), () {
      if (entry.mounted) entry.remove();
    });
  }

  /// Reabre o ecrã da senha a partir só do que o aviso global sabe (o
  /// ecrã original pode já ter sido fechado, ex.: por `goToRootTab` ao
  /// voltar ao início para tirar uma segunda senha). A localização e o
  /// serviço são reconstruídos a partir do `institutionId`/nome do
  /// serviço — só funciona para a localização piloto, a única que chega
  /// aqui (é a única que gera `LiveTicketRef`).
  Future<void> _openTicket(_TicketWatch watch) async {
    final ticket = watch.lastTicket;
    final nav = navigatorKey.currentState;
    if (ticket == null || nav == null) return;

    QueueLocation? location;
    for (final loc in MockData.locations) {
      if (loc.institutionId == watch.ref.institutionId) {
        location = loc;
        break;
      }
    }
    if (location == null) return;
    ServiceItem? service;
    for (final s in location.services) {
      if (s.name == ticket.service) {
        service = s;
        break;
      }
    }
    service ??= location.services.first;

    if (ticket.status == TicketStatus.serving) {
      final counterLabel = ticket.counterId == null
          ? null
          : await ticket_service.getCounterLabel(watch.ref.institutionId, watch.ref.branchId, ticket.counterId!);
      nav.push(MaterialPageRoute(
        builder: (_) => CalledScreen(
          location: location!,
          service: service!,
          liveTicket: watch.ref,
          ticketCode: ticket.code,
          counterLabel: counterLabel,
        ),
      ));
    } else {
      nav.push(MaterialPageRoute(
        builder: (_) => AlmostScreen(location: location!, service: service!, liveTicket: watch.ref),
      ));
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _GlobalAlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _GlobalAlertBanner({required this.title, required this.subtitle, required this.onTap, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onTap,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppColors.heroGradient,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 20, offset: const Offset(0, 8))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                      child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close, color: Colors.white70, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
