import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../auth/require_auth.dart';
import '../domain/institution_category.dart';
import '../location_service.dart' as location_service;
import '../models/favorite.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import 'institution_logo.dart';
import 'status_pill.dart';

/// Cartão de fila/instituição (marca): fundo branco, cantos 16px, borda
/// 0.5px, barra de cor vertical de 4px à esquerda (sem arredondar)
/// identificando a categoria (verde-menta = serviço público, âmbar =
/// banco). Substitui `LocationCard` como o cartão de referência da app --
/// mantém o mesmo comportamento (distância real, contagem ao vivo,
/// favorito), só com a linguagem visual nova.
class InstitutionCard extends StatelessWidget {
  final QueueLocation location;
  final VoidCallback onTap;
  final bool showFavorite;

  const InstitutionCard({super.key, required this.location, required this.onTap, this.showFavorite = true});

  Future<void> _toggleFavorite(BuildContext context) async {
    final institutionId = location.institutionId;
    final branchId = location.branchId;
    if (institutionId == null || branchId == null) return;
    final ok = await requireAuth(context, reason: 'Precisa de uma conta para guardar favoritos.');
    if (!ok) return;
    await favoritesStore.toggle(institutionId, branchId);
  }

  @override
  Widget build(BuildContext context) {
    final category = categoryOf(location);
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Barra de categoria -- sem arredondar de propósito
                // (regra da marca), mesmo o cartão à volta sendo
                // arredondado.
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: category.color,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InstitutionLogo(
                          institutionId: location.institutionId ?? '',
                          monogram: location.monogram,
                          color: location.brandColor,
                          size: 48,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(location.name, style: AppTextStyles.bodyStrong.copyWith(fontSize: 14, height: 1.25)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.place_outlined, size: 13, color: AppColors.textSecondary),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(location.address, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  ValueListenableBuilder(
                                    valueListenable: location_service.currentPosition,
                                    builder: (context, _, __) {
                                      final realKm = location_service.realDistanceKm(location.latitude, location.longitude);
                                      final label = realKm != null
                                          ? (realKm < 1 ? '${(realKm * 1000).round()} m' : '${realKm.toStringAsFixed(1)} km')
                                          : location.distance;
                                      return Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w500));
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: [
                                  if (location.institutionId != null)
                                    StreamBuilder<int>(
                                      stream: location.branchId == null
                                          ? const Stream<int>.empty()
                                          : ticket_service.subscribeQueueSize(location.institutionId!, location.branchId!),
                                      builder: (context, snapshot) => StatusPill(
                                        label: snapshot.hasData ? '${snapshot.data} pessoas · ao vivo' : 'ao vivo',
                                        color: category.onDark,
                                        background: category.background,
                                        icon: Icons.podcasts,
                                      ),
                                    )
                                  else
                                    StatusPill(
                                      label: '${location.peopleInQueue} pessoas',
                                      color: category.onDark,
                                      background: category.background,
                                    ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                                      const SizedBox(width: 3),
                                      Text('${location.etaMinutes} min', style: AppTextStyles.bodySmall),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (showFavorite && location.institutionId != null) ...[
                          const SizedBox(width: 4),
                          ValueListenableBuilder<List<Favorite>>(
                            valueListenable: favoritesStore,
                            builder: (context, favorites, _) {
                              final isFav = authService.currentUser != null &&
                                  favoritesStore.isFavorite(location.institutionId!, location.branchId!);
                              return Semantics(
                                label: isFav ? 'Remover ${location.name} dos favoritos' : 'Adicionar ${location.name} aos favoritos',
                                button: true,
                                toggled: isFav,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => _toggleFavorite(context),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: Icon(
                                      isFav ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: isFav ? AppColors.pink : AppColors.textSecondary,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
