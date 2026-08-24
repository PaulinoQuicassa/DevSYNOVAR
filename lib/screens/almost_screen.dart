import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/ticket_progress_row.dart';
import 'called_screen.dart';

class AlmostScreen extends StatefulWidget {
  final QueueLocation location;
  final ServiceItem service;
  final LiveTicketRef? liveTicket;

  const AlmostScreen({super.key, required this.location, required this.service, this.liveTicket});

  @override
  State<AlmostScreen> createState() => _AlmostScreenState();
}

class _AlmostScreenState extends State<AlmostScreen> {
  bool _alertsEnabled = true;

  LiveTicket? _ticket;
  LiveBoardEntry? _liveBoardEntry;
  bool _navigatedToCalled = false;

  StreamSubscription<LiveTicket?>? _ticketSub;
  StreamSubscription<LiveBoardEntry?>? _boardSub;

  @override
  void initState() {
    super.initState();
    final ref = widget.liveTicket;
    if (ref == null) return;
    _ticketSub = ticket_service.subscribeTicket(ref).listen(_onTicketUpdate);
    _boardSub = ticket_service.subscribeLiveBoardCurrent(ref.institutionId, ref.branchId).listen((entry) {
      if (mounted) setState(() => _liveBoardEntry = entry);
    });
  }

  void _onTicketUpdate(LiveTicket? ticket) {
    if (!mounted) return;
    setState(() => _ticket = ticket);
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
    super.dispose();
  }

  Future<void> _leaveQueue() async {
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
    if (ref != null) unawaited(ticket_service.cancelTicket(ref));
    if (mounted) goToRootTab(context, 0);
  }

  Future<void> _openWhatsapp() async {
    final displayCode = _ticket?.code ?? MockData.currentTicket;
    final ok = await launchUrl(
      Uri.parse('https://wa.me/${MockData.supportWhatsapp}?text=${Uri.encodeComponent("Olá, estou na fila $displayCode em ${widget.location.name}.")}'),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')));
    }
  }

  void _showQueueDetails() {
    final wired = widget.liveTicket != null;
    final displayCode = wired ? (_ticket?.code ?? '…') : MockData.currentTicket;
    final servingCounterLabel = wired ? (_liveBoardEntry?.counterLabel ?? '—') : 'Balcão ${MockData.counterNumber}';
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const Text('Detalhes da fila', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(widget.service.name, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _DetailStat(label: 'A sua senha', value: displayCode),
                    const _DetailStat(label: 'À sua frente', value: '2'),
                    _DetailStat(label: 'Balcão', value: servingCounterLabel),
                  ],
                ),
                const SizedBox(height: 20),
                if (!wired)
                  const TicketProgressRow(
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          const ScreenHeader(
            title: 'Está quase!',
            subtitle: 'Falta pouco para ser a sua vez.',
            trailingIcon: Icons.notifications_none_rounded,
            trailingHasDot: true,
          ),
          const SizedBox(height: 8),
          LocationSummaryCard(location: widget.location, tag: widget.service.name),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CalledScreen(location: widget.location, service: widget.service)),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppColors.almostGradient,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 14))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                        child: const Icon(Icons.notifications_active, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          'Está quase na sua vez!',
                          style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Faltam apenas algumas pessoas para a sua chamada.',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.4),
                  ),
                  const SizedBox(height: 22),
                  const Row(
                    children: [
                      Expanded(child: _AlmostStat(value: '2', label: 'pessoas\nà sua frente')),
                      Expanded(child: _AlmostStat(value: '5 min', label: 'tempo\nestimado')),
                      Expanded(child: _AlmostStat(value: MockData.counterNumber, label: 'Balcão')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: Colors.white24),
                  const SizedBox(height: 16),
                  TicketProgressRow(
                    tickets: MockData.ticketProgress,
                    current: MockData.currentTicket,
                    bubbleColor: Colors.white.withValues(alpha: 0.18),
                    bubbleTextColor: Colors.white,
                    activeColor: AppColors.amber,
                    activeTextColor: Colors.white,
                    lineColor: Colors.white24,
                    captionColor: AppColors.amber,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.warningBg, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.phone_android, color: AppColors.warning, size: 22),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vamos avisar quando for a sua vez', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      SizedBox(height: 2),
                      Text(
                        'Pode continuar a acompanhar aqui ou receber notificações no seu telemóvel.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openWhatsapp,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 15, color: Color(0xFF25D366)),
                          SizedBox(height: 2),
                          Text('WhatsApp', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.campaign_outlined, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Última senha chamada', style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      SizedBox(height: 2),
                      Text('${MockData.lastCalledTicket}  ·  Balcão ${MockData.counterNumber}',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: _showQueueDetails,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt_outlined, size: 16, color: AppColors.textPrimary),
                          SizedBox(width: 8),
                          Flexible(child: Text('Ver detalhes da fila', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(child: Text('Alertas', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                      Switch.adaptive(
                        value: _alertsEnabled,
                        onChanged: (v) => setState(() => _alertsEnabled = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlineButton(
            label: 'Sair da fila',
            icon: Icons.close,
            color: AppColors.critical,
            onTap: _leaveQueue,
          ),
          const SizedBox(height: 12),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => showContactSheet(
                context,
                title: 'Contactar suporte',
                phone: MockData.supportPhone,
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
                          Text('Fale com a nossa equipa de suporte.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                    const Text('Contactar suporte', style: TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.w700)),
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

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;

  const _DetailStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _AlmostStat extends StatelessWidget {
  final String value;
  final String label;

  const _AlmostStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.amber, fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.25)),
      ],
    );
  }
}
