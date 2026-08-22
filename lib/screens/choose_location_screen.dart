import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../widgets/flow_scaffold.dart';
import '../widgets/location_card.dart';
import '../widgets/screen_header.dart';
import 'choose_service_screen.dart';

const _nearbyThresholdKm = 5.0;

class ChooseLocationScreen extends StatefulWidget {
  final bool isScheduling;

  const ChooseLocationScreen({super.key, this.isScheduling = false});

  @override
  State<ChooseLocationScreen> createState() => _ChooseLocationScreenState();
}

class _ChooseLocationScreenState extends State<ChooseLocationScreen> {
  bool _nearbyOnly = true;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<QueueLocation> get _filtered {
    var list = MockData.locations.toList()..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    if (_nearbyOnly) {
      list = list.where((loc) => loc.distanceKm <= _nearbyThresholdKm).toList();
    }
    if (_query.trim().isNotEmpty) {
      final q = _query.trim().toLowerCase();
      list = list
          .where((loc) =>
              loc.name.toLowerCase().contains(q) ||
              loc.subtitle.toLowerCase().contains(q) ||
              loc.address.toLowerCase().contains(q))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _filtered;

    return FlowScaffold(
      currentIndex: widget.isScheduling ? 3 : 2,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ScreenHeader(
              title: widget.isScheduling ? 'Novo agendamento' : 'Escolher localização',
              subtitle: 'Selecione o local onde deseja ser atendido.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
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
                              hintText: 'Pesquisar banco, agência ou serviço',
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
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChip(
                    label: 'Próximos de si',
                    icon: Icons.place_outlined,
                    selected: _nearbyOnly,
                    onTap: () => setState(() => _nearbyOnly = true),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FilterChip(
                    label: 'Todas as localizações',
                    icon: Icons.apartment_outlined,
                    selected: !_nearbyOnly,
                    onTap: () => setState(() => _nearbyOnly = false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: results.isEmpty
                ? _EmptyResults(query: _query)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      ...results.map(
                        (loc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LocationCard(
                            location: loc,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ChooseServiceScreen(location: loc, isScheduling: widget.isScheduling),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: const Color(0xFFEAF0FE), borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: const Icon(Icons.phone_iphone, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Entre na fila onde estiver', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                  SizedBox(height: 3),
                                  Text(
                                    'Receba notificações em tempo real e seja chamado quando estiver perto da sua vez.',
                                    style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyResults extends StatelessWidget {
  final String query;

  const _EmptyResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.background, shape: BoxShape.circle),
              child: const Icon(Icons.search_off, color: AppColors.textMuted, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              query.isEmpty ? 'Sem localizações nesta categoria' : 'Sem resultados para "$query"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tenta outra pesquisa ou muda para "Todas as localizações".',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: selected ? null : Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
