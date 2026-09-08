import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../domain/queue_insights.dart';
import '../location_service.dart' as location_service;
import '../models/queue_location.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';
import '../widgets/institution_card.dart';
import '../widgets/queue_insight_widgets.dart';
import 'choose_service_screen.dart';
import 'service_confirm_screen.dart';

const _nearbyThresholdKm = 5.0;

double _effectiveDistanceKm(QueueLocation location) =>
    location_service.realDistanceKm(location.latitude, location.longitude) ?? location.distanceKm;

class _ServiceResult {
  final QueueLocation location;
  final ServiceItem service;

  const _ServiceResult(this.location, this.service);
}

/// "Explorar" (Fila Certa 2.0) -- descoberta sem exigir conta (secção 4 e
/// 7 do master prompt): pesquisa por serviço em todas as instituições
/// (não só dentro de uma já escolhida, ao contrário do antigo fluxo
/// Localização→Serviço), instituições próximas, e recomendação de melhor
/// unidade quando o mesmo serviço existe em mais do que um sítio (secção
/// 10). Substitui `ChooseLocationScreen` como raiz deste separador --
/// `ChooseLocationScreen` continua a existir só para o fluxo de
/// agendamento (`isScheduling: true`), inalterado.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _query = '';
  bool _nearbyOnly = false;

  @override
  void initState() {
    super.initState();
    location_service.currentPosition.addListener(_onPositionChanged);
    location_service.ensureCurrentPosition();
    _applyPendingQuery();
    pendingExploreQuery.addListener(_applyPendingQuery);
  }

  // A Home escreve aqui (`pendingExploreQuery`) e muda de separador --
  // este ecrã, mantido vivo pelo IndexedStack do RootShell, aplica a
  // pesquisa e devolve o foco ao campo para o utilizador continuar a
  // escrever de imediato, exactamente como pedido: a pesquisa entra
  // directamente em modo de resultados, nunca na lista de instituições
  // (essa continua a ser só o botão "Instituições"/"Perto de mim").
  void _applyPendingQuery() {
    final query = pendingExploreQuery.value;
    if (query == null) return;
    pendingExploreQuery.value = null;
    if (!mounted) return;
    setState(() {
      _query = query;
      _searchController.text = query;
      _searchController.selection = TextSelection.collapsed(offset: query.length);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _onPositionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    location_service.currentPosition.removeListener(_onPositionChanged);
    pendingExploreQuery.removeListener(_applyPendingQuery);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<_ServiceResult> get _serviceResults {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <_ServiceResult>[];
    for (final location in MockData.locations) {
      for (final service in location.services) {
        if (service.name.toLowerCase().contains(q) || service.description.toLowerCase().contains(q)) {
          results.add(_ServiceResult(location, service));
        }
      }
    }
    results.sort((a, b) => _effectiveDistanceKm(a.location).compareTo(_effectiveDistanceKm(b.location)));
    return results;
  }

  List<QueueLocation> get _locationResults {
    final q = _query.trim().toLowerCase();
    var list = MockData.locations.toList()..sort((a, b) => _effectiveDistanceKm(a).compareTo(_effectiveDistanceKm(b)));
    if (_nearbyOnly) {
      list = list.where((loc) => _effectiveDistanceKm(loc) <= _nearbyThresholdKm).toList();
    }
    if (q.isNotEmpty) {
      list = list.where((loc) => loc.name.toLowerCase().contains(q) || loc.subtitle.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _openService(_ServiceResult r) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ServiceConfirmScreen(location: r.location, service: r.service)),
    );
  }

  void _openLocation(QueueLocation loc) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ChooseServiceScreen(location: loc)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final serviceResults = _serviceResults;
    final locationResults = _locationResults;

    // Recomendação de melhor unidade (secção 10): só faz sentido quando a
    // pesquisa aponta claramente para o mesmo serviço em >1 localização.
    UnitRecommendation? recommendation;
    if (serviceResults.length > 1) {
      final sameNameLocations = serviceResults.map((r) => r.location).toSet().toList();
      if (sameNameLocations.length > 1) {
        recommendation = recommendBestUnit(sameNameLocations, distanceOf: _effectiveDistanceKm);
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('Explorar', style: AppTextStyles.h1),
        const SizedBox(height: 4),
        const Text('O que precisa de tratar hoje?', style: AppTextStyles.bodySmall),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: AppColors.textMuted),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                    hintText: 'Ex.: Renovar BI, atendimento bancário…',
                    hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                  ),
                ),
              ),
              if (_query.isNotEmpty)
                InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  onTap: () => setState(() {
                    _searchController.clear();
                    _query = '';
                  }),
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, size: 16, color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (query.isNotEmpty) ...[
          Text('Serviços para "$query"', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          if (recommendation != null) ...[
            RecommendationCard(location: recommendation.best, reason: recommendation.reason),
            const SizedBox(height: 12),
          ],
          if (serviceResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.search_off, color: AppColors.textMuted, size: 28),
                    SizedBox(height: 10),
                    Text('Não encontrámos este serviço perto de si.', style: AppTextStyles.bodyStrong, textAlign: TextAlign.center),
                    SizedBox(height: 4),
                    Text('Experimente procurar outro serviço, ou limpe a pesquisa para ver as instituições.',
                        style: AppTextStyles.bodySmall, textAlign: TextAlign.center),
                  ],
                ),
              ),
            )
          else
            ...serviceResults.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceResultCard(result: r, onTap: () => _openService(r)),
                )),
          const SizedBox(height: 20),
        ],
        // A lista de instituições é o que o botão "Instituições"/"Perto
        // de mim" mostra -- durante uma pesquisa activa fica escondida,
        // para escrever aqui nunca "levar à lista de instituições" (só
        // aos resultados do serviço procurado).
        if (query.isEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('instituições', style: AppTextStyles.h3),
              _FilterChip(label: _nearbyOnly ? 'Perto de si' : 'Todas', onTap: () => setState(() => _nearbyOnly = !_nearbyOnly)),
            ],
          ),
          const SizedBox(height: 10),
          if (locationResults.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sem instituições nesta categoria.', style: AppTextStyles.bodySmall),
            )
          else
            ...locationResults.map((loc) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InstitutionCard(location: loc, onTap: () => _openLocation(loc)),
                )),
        ],
      ],
    );
  }
}

class _ServiceResultCard extends StatelessWidget {
  final _ServiceResult result;
  final VoidCallback onTap;

  const _ServiceResultCard({required this.result, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final location = result.location;
    final service = result.service;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: service.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                child: Icon(service.icon, color: service.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(service.name, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 2),
                    Text(location.name, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              WaitTimeDisplay(minutes: service.etaMinutes, peopleInQueue: service.peopleInQueue, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryTint,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.place_outlined, size: 14, color: AppColors.primary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
