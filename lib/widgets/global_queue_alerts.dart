import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../models/live_ticket.dart';
import '../theme/app_theme.dart';
import '../ticket_navigation.dart';
import '../ticket_service.dart' as ticket_service;

/// Watches every ref in [activeTicketStore] for the whole authenticated
/// session (see `auth_gate.dart`, wraps [RootShell]) so every important
/// moment no balcão — chamado, quase a ser chamado, chamado novamente,
/// concluído, transferido, não compareceu, balcão em pausa — continua a
/// alertar com som mesmo quando o cliente andou noutro separador, onde
/// os ecrãs da fila (`QueueScreen`/`AlmostScreen`) e as suas subscrições
/// já não existem (`goToRootTab` fecha-os por completo) — incluindo
/// quando isso aconteceu porque o cliente voltou atrás para tirar uma
/// *segunda* senha para outro serviço enquanto a primeira ainda esperava.
///
/// Cada senha é seguida de forma independente (por `ticketId`) — nunca só
/// a mais recente.
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
  DateTime? lastBoardUpdatedAt;
  String? lastCounterStatus;
  String? watchedCounterId;

  StreamSubscription<LiveTicket?>? ticketSub;
  StreamSubscription<int>? aheadSub;
  StreamSubscription<LiveBoardEntry?>? boardSub;
  StreamSubscription<String?>? counterSub;

  _TicketWatch(this.ref);

  void cancel() {
    ticketSub?.cancel();
    aheadSub?.cancel();
    boardSub?.cancel();
    counterSub?.cancel();
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
    final previousStatus = watch.lastStatus;
    watch.lastTicket = ticket;

    if (watch.aheadSub == null && ticket.createdAt != null) {
      watch.aheadSub = ticket_service.subscribeWaitingAhead(watch.ref, ticket.createdAt!).listen((count) {
        _onAhead(watch, count);
      });
    }

    if (ticket.status == TicketStatus.serving) {
      _ensureBoardSub(watch);
      _ensureCounterSub(watch, ticket.counterId);
    }

    if (ticket.status == TicketStatus.serving && previousStatus != TicketStatus.serving) {
      _showAlert(watch, 'É a sua vez!', '${ticket.service} — dirija-se ao balcão indicado.');
    } else if (ticket.status == TicketStatus.waiting && previousStatus == TicketStatus.serving) {
      _showAlert(watch, 'A sua senha foi transferida', '${ticket.service} voltou à fila de espera.');
    } else if (ticket.status == TicketStatus.done && previousStatus != TicketStatus.done) {
      _showAlert(watch, 'Atendimento concluído', 'O seu atendimento de ${ticket.service} terminou.');
    } else if (ticket.status == TicketStatus.noShow &&
        ticket.noShowReason == NoShowReason.staffMarked &&
        previousStatus != TicketStatus.noShow) {
      _showAlert(watch, 'Marcado como ausente', 'A sua senha de ${ticket.service} foi marcada como não comparecida.');
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

  /// "Chamar Novamente" não muda nenhum campo da senha (só o painel ao
  /// vivo) — mesmo truque já usado localmente em `CalledScreen`: comparar
  /// o código no `liveBoard/current` com o desta senha e reparar quando
  /// `updatedAt` muda outra vez.
  void _ensureBoardSub(_TicketWatch watch) {
    if (watch.boardSub != null) return;
    watch.boardSub = ticket_service.subscribeLiveBoardCurrent(watch.ref.institutionId, watch.ref.branchId).listen((entry) {
      if (entry == null) return;
      final myCode = watch.lastTicket?.code;
      final isRecall = myCode != null &&
          entry.code == myCode &&
          watch.lastBoardUpdatedAt != null &&
          entry.updatedAt != null &&
          entry.updatedAt != watch.lastBoardUpdatedAt;
      watch.lastBoardUpdatedAt = entry.updatedAt ?? watch.lastBoardUpdatedAt;
      if (isRecall) {
        _showAlert(watch, 'Estão a chamar-te novamente!', '${watch.lastTicket?.service ?? ''} — dirija-se ao balcão.');
      }
    });
  }

  /// "Pausar Fila" não toca na senha, só no balcão que a está a atender —
  /// segue esse balcão assim que se sabe qual é.
  void _ensureCounterSub(_TicketWatch watch, String? counterId) {
    if (counterId == null || watch.watchedCounterId == counterId) return;
    watch.counterSub?.cancel();
    watch.watchedCounterId = counterId;
    watch.lastCounterStatus = null;
    watch.counterSub =
        ticket_service.subscribeCounterStatus(watch.ref.institutionId, watch.ref.branchId, counterId).listen((status) {
      if (status == 'paused' && watch.lastCounterStatus != 'paused') {
        _showAlert(watch, 'O balcão está em pausa', 'Aguarde, o atendimento vai continuar em breve.');
      }
      watch.lastCounterStatus = status;
    });
  }

  void _showAlert(_TicketWatch watch, String title, String subtitle) {
    // O registo fica sempre gravado (alimenta o sino de notificações);
    // só o som/banner é que depende da definição do utilizador.
    notificationsStore.add(title: title, subtitle: subtitle);

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
          final ticket = watch.lastTicket;
          final nav = navigatorKey.currentState;
          if (ticket != null && nav != null) openLiveTicketScreen(nav, watch.ref, ticket);
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
