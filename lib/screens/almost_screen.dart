import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/ticket_progress_row.dart';
import 'called_screen.dart';

class AlmostScreen extends StatelessWidget {
  final QueueLocation location;
  final ServiceItem service;

  const AlmostScreen({super.key, required this.location, required this.service});

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
          LocationSummaryCard(location: location, tag: service.name),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => CalledScreen(location: location, service: service)),
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
                Container(
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
                      Switch.adaptive(value: true, onChanged: (_) {}, activeThumbColor: AppColors.primary),
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
            onTap: () => goToRootTab(context, 0),
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
