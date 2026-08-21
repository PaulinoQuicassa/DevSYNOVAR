import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/info_banner.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/service_card.dart';
import '../widgets/status_pill.dart';
import 'queue_screen.dart';

class ChooseServiceScreen extends StatelessWidget {
  final QueueLocation location;

  const ChooseServiceScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return FlowScaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          const ScreenHeader(
            title: 'Escolher serviço',
            subtitle: 'Selecione o serviço que pretende.',
          ),
          const SizedBox(height: 8),
          LocationSummaryCard(
            location: location,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(
                  label: '${location.peopleInQueue} na fila geral',
                  color: location.load.color,
                  background: location.load.bgColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('${location.etaMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              children: [
                Icon(Icons.search, size: 18, color: AppColors.textMuted),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      hintText: 'Pesquisar serviço',
                      hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Serviços disponíveis', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.86,
            children: MockData.services
                .map(
                  (service) => ServiceCard(
                    service: service,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => QueueScreen(location: location, service: service)),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const InfoBanner(
            icon: Icons.notifications_active_outlined,
            title: 'Receba notificações',
            description: 'Vamos avisar quando estiver próximo da sua vez.',
          ),
        ],
      ),
    );
  }
}
