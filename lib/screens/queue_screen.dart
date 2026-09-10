import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../models/live_ticket.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/confirm_dialog.dart';
import '../widgets/connection_banner.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/ticket_progress_row.dart';
import 'almost_screen.dart';
import 'called_screen.dart';

class QueueScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;
  final LiveTicketRef? liveTicket;

  const QueueScreen({super.key, required this.location, required this.service, this.liveTicket});

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  LiveTicket? _ticket;
  LiveBoardEntry? _liveBoardEntry;
  int _peopleAhead = 0;
  bool _navigatedToCalled = false;
  bool _connectionLost = false;

  StreamSubscription<LiveTicket?>? _ticketSub;
  StreamSubscription<LiveBoardEntry?>? _boardSub;
  StreamSubscription<int>? _aheadSub;

  @override
  void initState() {
    super.initState();
    final ref = widget.liveTicket;
    if (ref == null) return;
    _ticketSub = ticket_service.subscribeTicket(ref).listen(_onTicketUpdate, onError: _onStreamError);
    _boardSub = ticket_service.subscribeLiveBoardCurrent(ref.institutionId, ref.branchId).listen((entry) {
      if (mounted) setState(() => _liveBoardEntry = entry);
    }, onError: _onStreamError);
  }

  void _onStreamError(Object _) {
    if (mounted) setState(() => _connectionLost = true);
  }

  void _onTicketUpdate(LiveTicket? ticket) {
    if (!mounted) return;
    final wasSubscribedToAhead = _ticket != null;
    setState(() {
      _ticket = ticket;
      _connectionLost = false;
    });
    if (!wasSubscribedToAhead && ticket?.createdAt != null) {
      _aheadSub = ticket_service.subscribeWaitingAhead(widget.liveTicket!, ticket!.createdAt!).listen((count) {
        if (mounted) setState(() => _peopleAhead = count);
      }, onError: _onStreamError);
    }
    if (ticket?.status == TicketStatus.serving && !_navigatedToCalled) {
      _navigatedToCalled = true;
      _goToCalled(ticket!);
    }
  }

  Future<void> _goToCalled(LiveTicket ticket) async {
    final counterLabel = ticket.counterId == null
        ? null
        : await ticket_service.getCounterLabel(widget.liveTicket!.institutionId, widget.liveTicket!.branchId, ticket.counterId!);
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CalledScreen(
          location: widget.location,
          service: widget.service,
          liveTicket: widget.liveTicket,
          ticketCode: ticket.code,
          counterLabel: counterLabel,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ticketSub?.cancel();
    _boardSub?.cancel();
    _aheadSub?.cancel();
    super.dispose();
  }

  Future<void> _leaveQueue(BuildContext context) async {
    final displayCode = _ticket?.code ?? MockData.currentTicket;
    final confirmed = await confirmAction(
      context,
      title: 'Sair da fila?',
      message: 'Perde a sua posição atual (senha $displayCode). Vai ter de entrar novamente na fila.',
      confirmLabel: 'Sair da fila',
      danger: true,
    );
    if (!confirmed) return;
    final ref = widget.liveTicket;
    if (ref != null) {
      try {
        await ticket_service.cancelTicket(ref);
      } catch (e, stackTrace) {
        unawaited(Sentry.captureException(e, stackTrace: stackTrace));
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível sair da fila. Tente novamente.')),
        );
        return;
      }
    }
    if (context.mounted) goToRootTab(context, 0);
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Como funciona a fila?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: const Text(
          'A sua senha avança automaticamente à medida que os balcões atendem. '
          'Não precisa de estar fisicamente no local — vamos avisá-lo quando estiver quase na sua vez e quando for chamado.',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Entendi', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wired = widget.liveTicket != null;
    final displayCode = wired ? (_ticket?.code ?? '…') : MockData.currentTicket;
    // '—' sozinho parecia um erro/ausência de dados. Numa agência nova,
    // sem histórico, é perfeitamente normal ainda ninguém ter sido
    // chamado -- deixar isso claro em vez de mostrar só um traço.
    final lastCalledCode = wired ? (_liveBoardEntry?.code ?? 'Ainda ninguém') : MockData.lastCalledTicket;
    final servingCounterLabel = wired ? (_liveBoardEntry?.counterLabel ?? '—') : 'Balcão ${MockData.counterNumber}';
    final peopleAheadText = wired ? '$_peopleAhead' : '4';
    final etaText = wired ? '${_peopleAhead * 5} min' : '12 min';

    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          ScreenHeader(
            title: 'A sua senha',
            trailingIcon: Icons.help_outline,
            onTrailing: () => _showHelp(context),
          ),
          ConnectionBanner(visible: _connectionLost),
          const SizedBox(height: 8),
          LocationSummaryCard(location: widget.location, tag: widget.service.name),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              children: [
                const Text('A sua senha é', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Text(
                  displayCode,
                  style: const TextStyle(color: Colors.white, fontSize: 68, fontWeight: FontWeight.w800, height: 1.05),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, size: 15, color: Colors.white),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tempo estimado: $etaText',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _HeroStat(icon: Icons.groups_outlined, value: peopleAheadText, label: 'pessoas\nà sua frente'),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    Expanded(
                      child: wired
                          ? _HeroStat(icon: Icons.category_outlined, value: widget.service.name, label: 'Serviço')
                          : const _HeroStat(icon: Icons.inbox_outlined, value: MockData.counterNumber, label: 'Balcão'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Última senha chamada', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(lastCalledCode, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 34, color: AppColors.border),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Em atendimento no balcão', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              const SizedBox(height: 4),
                              Text(servingCounterLabel, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (!wired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Progresso da fila', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  SizedBox(height: 14),
                  TicketProgressRow(
                    tickets: MockData.ticketProgress,
                    current: MockData.currentTicket,
                    bubbleColor: Color(0xFFE4EAFB),
                    bubbleTextColor: AppColors.primaryDark,
                    activeColor: AppColors.primary,
                    activeTextColor: Colors.white,
                    lineColor: Color(0xFFDCE3F5),
                    captionColor: AppColors.primary,
                  ),
                ],
              ),
            ),
          if (!wired) const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFEAF0FE), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.info_outline, size: 17, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Importante', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      SizedBox(height: 3),
                      Text(
                        'Fique atento às notificações. Dirija-se ao balcão assim que for chamado para evitar perder a sua vez.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlineButton(
                  label: 'Acompanhar fila',
                  icon: Icons.visibility_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlmostScreen(location: widget.location, service: widget.service, liveTicket: widget.liveTicket),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlineButton(
                  label: 'Sair da fila',
                  icon: Icons.close,
                  color: AppColors.critical,
                  onTap: () => _leaveQueue(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showContactSheet(
                context,
                title: 'Contactar ${widget.location.name}',
                phone: widget.location.phone,
                whatsapp: MockData.supportWhatsapp,
                email: MockData.supportEmail,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.support_agent_outlined, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Precisa de ajuda?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                          SizedBox(height: 2),
                          Text('Fale com o apoio ao cliente.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Text('Contactar', style: TextStyle(color: AppColors.primary, fontSize: 12.5, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _HeroStat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.25),
        ),
      ],
    );
  }
}
