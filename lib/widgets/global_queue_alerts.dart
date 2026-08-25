import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../models/live_ticket.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;

/// Watches [activeTicketStore] for the whole authenticated session (see
/// `auth_gate.dart`, wraps [RootShell]) so two important moments — "serás
/// o próximo" and "é a sua vez" — still alert the customer with sound
/// even when they've wandered off to another bottom-nav tab, where the
/// queue-flow screens (`QueueScreen`/`AlmostScreen`) and their own
/// Firestore subscriptions no longer exist (`goToRootTab` pops them off
/// the navigator entirely).
///
/// Deliberately narrow scope: only these two alerts are global. The
/// existing in-flow navigation to `CalledScreen` when actually called is
/// untouched — this just adds an always-on awareness layer on top of it.
class GlobalQueueAlerts extends StatefulWidget {
  final Widget child;

  const GlobalQueueAlerts({super.key, required this.child});

  @override
  State<GlobalQueueAlerts> createState() => _GlobalQueueAlertsState();
}

class _GlobalQueueAlertsState extends State<GlobalQueueAlerts> {
  LiveTicketRef? _ref;
  TicketStatus? _lastStatus;
  bool _announcedNext = false;

  StreamSubscription<LiveTicket?>? _ticketSub;
  StreamSubscription<int>? _aheadSub;

  @override
  void initState() {
    super.initState();
    activeTicketStore.addListener(_onRefChanged);
    _onRefChanged();
  }

  @override
  void dispose() {
    activeTicketStore.removeListener(_onRefChanged);
    _ticketSub?.cancel();
    _aheadSub?.cancel();
    super.dispose();
  }

  void _onRefChanged() {
    final ref = activeTicketStore.value;
    if (ref == _ref) return;
    _ref = ref;
    _ticketSub?.cancel();
    _aheadSub?.cancel();
    _aheadSub = null;
    _lastStatus = null;
    _announcedNext = false;
    if (ref != null) {
      _ticketSub = ticket_service.subscribeTicket(ref).listen(_onTicket);
    }
  }

  void _onTicket(LiveTicket? ticket) {
    final ref = _ref;
    if (ticket == null || ref == null) return;

    if (_aheadSub == null && ticket.createdAt != null) {
      _aheadSub = ticket_service.subscribeWaitingAhead(ref, ticket.createdAt!).listen(_onAhead);
    }

    if (ticket.status == TicketStatus.serving && _lastStatus != TicketStatus.serving) {
      _showAlert('É a sua vez!', 'Dirija-se ao balcão indicado.');
    }

    if (ticket.status == TicketStatus.done || ticket.status == TicketStatus.noShow) {
      activeTicketStore.value = null;
    }

    _lastStatus = ticket.status;
  }

  void _onAhead(int ahead) {
    if (ahead == 0 && !_announcedNext && _lastStatus == TicketStatus.waiting) {
      _announcedNext = true;
      _showAlert('Serás o próximo!', 'Prepare-se, a sua vez está a chegar.');
    }
  }

  void _showAlert(String title, String subtitle) {
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
        onDismiss: () {
          if (entry.mounted) entry.remove();
        },
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 5), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _GlobalAlertBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onDismiss;

  const _GlobalAlertBanner({required this.title, required this.subtitle, required this.onDismiss});

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
              onTap: onDismiss,
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
                    const Icon(Icons.close, color: Colors.white70, size: 18),
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
