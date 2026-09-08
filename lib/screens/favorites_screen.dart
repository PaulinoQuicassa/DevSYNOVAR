import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../data/mock_data.dart';
import '../models/favorite.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../widgets/institution_card.dart';
import 'choose_service_screen.dart';

/// "Os seus favoritos" (secção 26 do redesign).
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  QueueLocation? _findLocation(Favorite f) {
    for (final loc in MockData.locations) {
      if (loc.institutionId == f.institutionId && loc.branchId == f.branchId) return loc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        title: const Text('Favoritos', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<List<Favorite>>(
          valueListenable: favoritesStore,
          builder: (context, favorites, _) {
            final locations = favorites.map(_findLocation).whereType<QueueLocation>().toList();
            if (locations.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_outline_rounded, color: AppColors.textMuted, size: 40),
                      SizedBox(height: 12),
                      Text('Ainda sem favoritos', style: AppTextStyles.bodyStrong),
                      SizedBox(height: 6),
                      Text(
                        'Toque na estrela de uma instituição em "Explorar" para a guardar aqui.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: locations
                  .map((loc) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: InstitutionCard(
                          location: loc,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => ChooseServiceScreen(location: loc)),
                          ),
                        ),
                      ))
                  .toList(),
            );
          },
        ),
      ),
    );
  }
}
