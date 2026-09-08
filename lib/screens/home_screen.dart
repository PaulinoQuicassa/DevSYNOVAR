import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../data/mock_data.dart';
import '../location_service.dart' as location_service;
import '../models/favorite.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../widgets/gradient_button.dart';
import '../widgets/location_card.dart';
import '../auth/require_auth.dart';
import 'choose_service_screen.dart';
import 'favorites_screen.dart';

/// Saudação real conforme a hora actual do dispositivo — deixou de ser
/// sempre "Boa tarde".
String _greetingPhrase() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Bom dia,';
  if (hour < 19) return 'Boa tarde,';
  return 'Boa noite,';
}

/// Nome apresentável a partir do email da conta com sessão iniciada —
/// não há campo de nome no registo (`signup_screen.dart` só pede
/// email/palavra-passe), por isso usamos a parte antes do "@".
String _greetingName() {
  final email = authService.currentUser?.email;
  if (email == null || !email.contains('@')) return '';
  final local = email.split('@').first.replaceAll(RegExp(r'[._]'), ' ').trim();
  if (local.isEmpty) return '';
  return local.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
}

/// Home (Fila Certa 2.0) -- responde a "o que quer fazer hoje?" em vez de
/// ser só uma lista de instituições (secção 7 do redesign): pesquisa em
/// destaque, acções rápidas, favoritos (quando existem) e as filas mais
/// próximas com o tempo de espera como informação principal (secção 8).
/// Acessível sem conta -- só a secção de favoritos e o sino de
/// notificações mudam de comportamento consoante haja sessão.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    location_service.currentPosition.addListener(_onPositionChanged);
    location_service.ensureCurrentPosition();
    // O IndexedStack do RootShell constrói esta página uma única vez,
    // muitas vezes ainda em modo convidado -- sem isto, a saudação e o
    // sino de notificações nunca actualizariam depois de entrar na conta
    // a meio da utilização (ex.: ao confirmar entrada numa fila).
    _authSub = authService.userChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  void _onPositionChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    location_service.currentPosition.removeListener(_onPositionChanged);
    _authSub?.cancel();
    super.dispose();
  }

  void _openExplore(BuildContext context) => goToRootTab(context, 1);

  // A barra de pesquisa da Home escreve a consulta em `pendingExploreQuery`
  // e muda para o separador "Explorar", que a aplica directamente aos
  // resultados de serviço -- nunca à lista de instituições (essa
  // continua a ser só o botão "Encontrar um serviço"/"Instituições").
  void _submitSearch(BuildContext context, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    pendingExploreQuery.value = trimmed;
    goToRootTab(context, 1);
  }

  Future<void> _openFavorites(BuildContext context) async {
    final ok = await requireAuth(context, reason: 'Precisa de uma conta para guardar favoritos.');
    if (!ok || !context.mounted) return;
    Navigator.of(context, rootNavigator: true).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
  }

  void _openLocation(BuildContext context, QueueLocation location) {
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(builder: (_) => ChooseServiceScreen(location: location)),
    );
  }

  QueueLocation? _findLocation(Favorite f) {
    for (final loc in MockData.locations) {
      if (loc.institutionId == f.institutionId && loc.branchId == f.branchId) return loc;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = authService.currentUser != null;
    final nearby = MockData.locations.toList()
      ..sort((a, b) {
        final da = location_service.realDistanceKm(a.latitude, a.longitude) ?? a.distanceKm;
        final db = location_service.realDistanceKm(b.latitude, b.longitude) ?? b.distanceKm;
        return da.compareTo(db);
      });
    final nearestTwo = nearby.take(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // O acesso a notificações só existe a partir do Perfil (conta
          // obrigatória) -- sem atalho aqui na Home, mesmo para quem já
          // tem sessão iniciada.
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greetingPhrase(), style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Text(
                signedIn ? _greetingName() : 'Bem-vindo',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 14))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Não fique na fila.',
                  style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800, height: 1.15),
                ),
                const SizedBox(height: 6),
                Text(
                  'Entre na fila pelo telemóvel e saiba quando é a sua vez.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 16),
                _HomeSearchField(onSubmitted: (query) => _submitSearch(context, query)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: GradientButton(label: 'Encontrar um serviço', icon: Icons.search, onTap: () => _openExplore(context))),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _QuickAction(icon: Icons.place_outlined, label: 'Perto de mim', onTap: () => _openExplore(context))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.apartment_outlined, label: 'Instituições', onTap: () => _openExplore(context))),
              const SizedBox(width: 10),
              Expanded(child: _QuickAction(icon: Icons.confirmation_number_outlined, label: 'Minhas filas', onTap: () => goToRootTab(context, 2))),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickAction(
                  icon: Icons.star_outline_rounded,
                  label: 'Favoritos',
                  onTap: () => _openFavorites(context),
                ),
              ),
            ],
          ),
          if (signedIn) ...[
            const SizedBox(height: 28),
            ValueListenableBuilder<List<Favorite>>(
              valueListenable: favoritesStore,
              builder: (context, favorites, _) {
                final locations = favorites.map(_findLocation).whereType<QueueLocation>().take(3).toList();
                if (locations.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Os seus favoritos', style: AppTextStyles.h3),
                    const SizedBox(height: 14),
                    ...locations.map((loc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LocationCard(location: loc, onTap: () => _openLocation(context, loc)),
                        )),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 12),
          const Text('Filas perto de si', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          ...nearestTwo.map(
            (loc) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: LocationCard(location: loc, onTap: () => _openLocation(context, loc)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo de pesquisa real (não um botão disfarçado) -- escrever aqui e
/// submeter (Enter/ícone) leva directamente aos resultados desse
/// serviço em "Explorar", nunca à lista de instituições.
class _HomeSearchField extends StatefulWidget {
  final ValueChanged<String> onSubmitted;

  const _HomeSearchField({required this.onSubmitted});

  @override
  State<_HomeSearchField> createState() => _HomeSearchFieldState();
}

class _HomeSearchFieldState extends State<_HomeSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => widget.onSubmitted(_controller.text);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: _submit,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.search, size: 18, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.search,
                onSubmitted: widget.onSubmitted,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  hintText: 'O que precisa de tratar? Ex.: Renovar BI…',
                  hintStyle: TextStyle(fontSize: 13.5, color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 19, color: AppColors.primary),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
