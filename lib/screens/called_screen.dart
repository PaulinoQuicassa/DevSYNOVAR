import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../models/live_ticket.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/confirm_dialog.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/screen_header.dart';
import 'rating_screen.dart';

class CalledScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;
  final LiveTicketRef? liveTicket;
  final String? ticketCode;
  final String? counterLabel;

  const CalledScreen({
    super.key,
    required this.location,
    required this.service,
    this.liveTicket,
    this.ticketCode,
    this.counterLabel,
  });

  @override
  State<CalledScreen> createState() => _CalledScreenState();
}

class _CalledScreenState extends State<CalledScreen> {
  LiveTicket? _ticket;
  String? _counterStatus;
  bool _onTheWaySent = false;
  bool _handledTransition = false;
  DateTime? _lastBoardUpdatedAt;

  StreamSubscription<LiveTicket?>? _ticketSub;
  StreamSubscription<LiveBoardEntry?>? _boardSub;
  StreamSubscription<String?>? _counterSub;

  @override
  void initState() {
    super.initState();
    final ref = widget.liveTicket;
    if (ref == null) return;
    _ticketSub = ticket_service.subscribeTicket(ref).listen(_onTicketUpdate);
    _boardSub = ticket_service.subscribeLiveBoardCurrent(ref.institutionId, ref.branchId).listen(_onBoardUpdate);
  }

  @override
  void dispose() {
    _ticketSub?.cancel();
    _boardSub?.cancel();
    _counterSub?.cancel();
    super.dispose();
  }

  void _onTicketUpdate(LiveTicket? ticket) {
    if (!mounted) return;
    final previousStatus = _ticket?.status;
    setState(() => _ticket = ticket);
    if (ticket == null) return;

    final ref = widget.liveTicket;
    final counterId = ticket.counterId;
    if (ref != null && counterId != null && _counterSub == null) {
      _counterSub = ticket_service.subscribeCounterStatus(ref.institutionId, ref.branchId, counterId).listen((status) {
        if (mounted) setState(() => _counterStatus = status);
      });
    }

    if (_handledTransition) return;
    if (ticket.status == TicketStatus.done && previousStatus != TicketStatus.done) {
      _handledTransition = true;
      _announceThenNavigate(
        message: 'O seu atendimento foi concluído.',
        builder: () => RatingScreen(location: widget.location, service: widget.service),
      );
    } else if (ticket.status == TicketStatus.waiting && previousStatus == TicketStatus.serving) {
      _handledTransition = true;
      _announceThenPop('A sua senha foi transferida e voltou à fila de espera.');
    } else if (ticket.status == TicketStatus.noShow &&
        ticket.noShowReason == NoShowReason.staffMarked &&
        previousStatus != TicketStatus.noShow) {
      _handledTransition = true;
      _announceThenGoRoot('Foi marcado como ausente por não ter comparecido.');
    }
  }

  void _onBoardUpdate(LiveBoardEntry? entry) {
    if (!mounted || entry == null) return;
    final myCode = _ticket?.code ?? widget.ticketCode;
    final isRecall = myCode != null &&
        entry.code == myCode &&
        _lastBoardUpdatedAt != null &&
        entry.updatedAt != null &&
        entry.updatedAt != _lastBoardUpdatedAt;
    _lastBoardUpdatedAt = entry.updatedAt ?? _lastBoardUpdatedAt;
    if (!isRecall) return;
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.alert);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Estão a chamar-te novamente!')),
    );
  }

  Future<void> _announceThenNavigate({required String message, required Widget Function() builder}) async {
    await _showInfoDialog(message);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => builder()));
  }

  Future<void> _announceThenPop(String message) async {
    await _showInfoDialog(message);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _announceThenGoRoot(String message) async {
    await _showInfoDialog(message);
    if (!mounted) return;
    goToRootTab(context, 0);
  }

  Future<void> _showInfoDialog(String message) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _onTheWay() async {
    if (_onTheWaySent) return;
    final ref = widget.liveTicket;
    setState(() => _onTheWaySent = true);
    if (ref != null) unawaited(ticket_service.setOnTheWay(ref));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avisámos o balcão que está a caminho.')),
    );
  }

  Future<void> _cannotAttend(BuildContext context) async {
    final displayCode = _ticket?.code ?? widget.ticketCode ?? MockData.currentTicket;
    final confirmed = await confirmAction(
      context,
      title: 'Não pode comparecer?',
      message: 'A sua senha $displayCode será libertada e outra pessoa será chamada. Terá de entrar novamente na fila.',
      confirmLabel: 'Confirmar',
      danger: true,
    );
    if (!confirmed) return;
    final ref = widget.liveTicket;
    if (ref != null) unawaited(ticket_service.cancelTicket(ref));
    if (context.mounted) goToRootTab(context, 0);
  }

  @override
  Widget build(BuildContext context) {
    final wired = widget.liveTicket != null;
    final displayCode = wired ? (_ticket?.code ?? widget.ticketCode ?? '…') : MockData.currentTicket;
    final counterDisplay = wired ? (widget.counterLabel ?? '—') : 'Balcão ${MockData.counterNumber}';
    final now = TimeOfDay.now();
    final callTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final counterPaused = _counterStatus == 'paused';

    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          const ScreenHeader(
            title: 'É a sua vez!',
            subtitle: 'Dirija-se ao balcão indicado.',
            trailingIcon: Icons.notifications_none_rounded,
            trailingHasDot: true,
          ),
          const SizedBox(height: 8),
          if (counterPaused)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                children: [
                  Icon(Icons.pause_circle_outline, color: AppColors.warning, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'O balcão está em pausa neste momento. Aguarde, vai ser retomado em breve.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                            child: const Icon(Icons.notifications_active, color: Colors.white, size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('É a sua vez!', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const Text('Senha', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        displayCode,
                        style: const TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w800, height: 1.05),
                      ),
                      const SizedBox(height: 16),
                      const Text('Dirija-se ao', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(
                        counterDisplay.toUpperCase(),
                        style: const TextStyle(color: AppColors.amber, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.account_balance_outlined, size: 16, color: Colors.white),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${widget.location.name}\n${widget.location.subtitle}',
                                style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0x33000000),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: Colors.white),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Se não puder comparecer, avise-nos. Assim podemos chamar outra pessoa.',
                          style: TextStyle(color: Colors.white, fontSize: 11.5, height: 1.35),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () => _cannotAttend(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Não posso comparecer', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Detalhes do atendimento', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(height: 12),
                _DetailRow(icon: Icons.groups_outlined, label: 'Serviço', value: widget.service.name),
                _DetailRow(icon: Icons.place_outlined, label: 'Local', value: widget.location.subtitle),
                _DetailRow(icon: Icons.access_time, label: 'Tempo de espera', value: '${widget.service.etaMinutes} min'),
                _DetailRow(icon: Icons.event_outlined, label: 'Hora da chamada', value: callTime, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEAF0FE), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dica', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      SizedBox(height: 2),
                      Text(
                        'Aproxime-se do balcão e apresente a sua senha assim que chegar.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _onTheWaySent ? 'Aviso enviado ✓' : 'Estou a caminho',
            icon: Icons.check_circle_outline,
            gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF15803D)]),
            shadowColor: AppColors.success,
            onTap: _onTheWaySent ? null : _onTheWay,
          ),
          const SizedBox(height: 10),
          OutlineButton(
            label: 'Ver direção até ao local',
            icon: Icons.near_me_outlined,
            onTap: () => openMapsDirections(context, '${widget.location.name}, ${widget.location.address}'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({required this.icon, required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
