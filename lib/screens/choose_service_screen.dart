import 'package:flutter/material.dart';
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/info_banner.dart';
import '../widgets/location_summary_card.dart';
import '../widgets/screen_header.dart';
import '../widgets/service_card.dart';
import '../widgets/status_pill.dart';
import 'schedule_datetime_screen.dart';
import 'queue_screen.dart';

class ChooseServiceScreen extends StatefulWidget {
  final QueueLocation location;
  final bool isScheduling;

  const ChooseServiceScreen({super.key, required this.location, this.isScheduling = false});

  @override
  State<ChooseServiceScreen> createState() => _ChooseServiceScreenState();
}

class _ChooseServiceScreenState extends State<ChooseServiceScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceItem> get _filtered {
    final all = widget.location.services;
    if (_query.trim().isEmpty) return all;
    final q = _query.trim().toLowerCase();
    return all.where((s) => s.name.toLowerCase().contains(q) || s.description.toLowerCase().contains(q)).toList();
  }

  void _selectService(BuildContext context, ServiceItem service) {
    if (widget.isScheduling) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ScheduleDateTimeScreen(location: widget.location, service: service)),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => QueueScreen(location: widget.location, service: service)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return FlowScaffold(
      currentIndex: widget.isScheduling ? 3 : 2,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        children: [
          ScreenHeader(
            title: widget.isScheduling ? 'Novo agendamento' : 'Escolher serviço',
            subtitle: 'Selecione o serviço que pretende.',
          ),
          const SizedBox(height: 8),
          LocationSummaryCard(
            location: widget.location,
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusPill(
                  label: '${widget.location.peopleInQueue} na fila geral',
                  color: widget.location.load.color,
                  background: widget.location.load.bgColor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text('${widget.location.etaMinutes} min', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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
            child: Row(
              children: [
                const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                      hintText: 'Pesquisar serviço',
                      hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                    ),
                  ),
                ),
                if (_query.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() {
                      _searchController.clear();
                      _query = '';
                    }),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 16, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('Serviços disponíveis', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          if (results.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text('Sem serviços para "$_query"', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ),
            )
          else
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.86,
              children: results
                  .map((service) => ServiceCard(service: service, onTap: () => _selectService(context, service)))
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
