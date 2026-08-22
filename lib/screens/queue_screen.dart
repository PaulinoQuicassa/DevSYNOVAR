import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/ticket_progress_row.dart';
import 'almost_screen.dart';

class QueueScreen extends StatelessWidget {
  final QueueLocation location;
  final ServiceItem service;

  const QueueScreen({super.key, required this.location, required this.service});

  Future<void> _leaveQueue(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Sair da fila?',
      message: 'Perde a sua posição atual (senha ${MockData.currentTicket}). Vai ter de entrar novamente na fila.',
      confirmLabel: 'Sair da fila',
      danger: true,
    );
    if (confirmed && context.mounted) goToRootTab(context, 0);
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
    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          ScreenHeader(
            title: 'A sua senha',
            trailingIcon: Icons.help_outline,
            onTrailing: () => _showHelp(context),
          ),
          const SizedBox(height: 8),
          LocationSummaryCard(location: location, tag: service.name),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              children: [
                const Text('A sua senha é', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                const Text(
                  MockData.currentTicket,
                  style: TextStyle(color: Colors.white, fontSize: 68, fontWeight: FontWeight.w800, height: 1.05),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(999)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.access_time, size: 15, color: Colors.white),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Tempo estimado: 12 min',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Expanded(
                      child: _HeroStat(icon: Icons.groups_outlined, value: '4', label: 'pessoas\nà sua frente'),
                    ),
                    Container(width: 1, height: 44, color: Colors.white24),
                    const Expanded(
                      child: _HeroStat(icon: Icons.inbox_outlined, value: MockData.counterNumber, label: 'Balcão'),
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
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Última senha chamada', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            SizedBox(height: 4),
                            Text(MockData.lastCalledTicket, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 34, color: AppColors.border),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Em atendimento no balcão', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              SizedBox(height: 4),
                              Text(MockData.counterNumber, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
          const SizedBox(height: 16),
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
                    MaterialPageRoute(builder: (_) => AlmostScreen(location: location, service: service)),
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
                title: 'Contactar ${location.name}',
                phone: location.phone,
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
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, height: 1)),
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
