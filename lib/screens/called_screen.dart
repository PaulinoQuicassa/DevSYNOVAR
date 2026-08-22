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
import '../widgets/screen_header.dart';
import 'rating_screen.dart';

class CalledScreen extends StatelessWidget {
  final QueueLocation location;
  final ServiceItem service;

  const CalledScreen({super.key, required this.location, required this.service});

  Future<void> _cannotAttend(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Não pode comparecer?',
      message: 'A sua senha ${MockData.currentTicket} será libertada e outra pessoa será chamada. Terá de entrar novamente na fila.',
      confirmLabel: 'Confirmar',
      danger: true,
    );
    if (confirmed && context.mounted) goToRootTab(context, 0);
  }

  @override
  Widget build(BuildContext context) {
    final now = TimeOfDay.now();
    final callTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
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
                      const Text(
                        MockData.currentTicket,
                        style: TextStyle(color: Colors.white, fontSize: 58, fontWeight: FontWeight.w800, height: 1.05),
                      ),
                      const SizedBox(height: 16),
                      const Text('Dirija-se ao', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const Text(
                        'BALCÃO ${MockData.counterNumber}',
                        style: TextStyle(color: AppColors.amber, fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5),
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
                                '${location.name}\n${location.subtitle}',
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
                _DetailRow(icon: Icons.groups_outlined, label: 'Serviço', value: service.name),
                _DetailRow(icon: Icons.place_outlined, label: 'Local', value: location.subtitle),
                _DetailRow(icon: Icons.access_time, label: 'Tempo de espera', value: '${service.etaMinutes} min'),
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
            label: 'Estou a caminho',
            icon: Icons.check_circle_outline,
            gradient: const LinearGradient(colors: [AppColors.success, Color(0xFF15803D)]),
            shadowColor: AppColors.success,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RatingScreen(location: location, service: service)),
            ),
          ),
          const SizedBox(height: 10),
          OutlineButton(
            label: 'Ver direção até ao local',
            icon: Icons.near_me_outlined,
            onTap: () => openMapsDirections(context, '${location.name}, ${location.address}'),
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
