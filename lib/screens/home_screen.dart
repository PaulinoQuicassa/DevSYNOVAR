import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_state.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../auth/require_auth.dart';
import '../data/mock_data.dart';
import '../domain/institution_category.dart';
import '../location_service.dart' as location_service;
import '../models/favorite.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../widgets/institution_card.dart';
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

/// Home -- aplica o design system oficial da marca (master prompt de
/// design, 2026-09-08): hero coral com forma orgânica, único ponto de
/// entrada (barra de pesquisa que funciona como botão de navegação,
/// nunca duplicada por um botão separado para o mesmo destino), chips de
/// categoria, e o novo `InstitutionCard`. Acessível sem conta -- só
/// favoritos mudam de comportamento consoante haja sessão (notificações
/// já não têm nenhum atalho aqui, só pelo Perfil).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<User?>? _authSub;
  InstitutionCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    location_service.currentPosition.addListener(_onPositionChanged);
    location_service.ensureCurrentPosition();
    // O IndexedStack do RootShell constrói esta página uma única vez,
    // muitas vezes ainda em modo convidado -- sem isto, a saudação nunca
    // actualizaria depois de entrar na conta a meio da utilização.
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

  // Único ponto de entrada da pesquisa (regra da marca: nunca duplicar
  // um campo de pesquisa com um botão separado para o mesmo destino) --
  // muda para "Explorar" e devolve logo o foco ao campo real de
  // pesquisa lá, pronto para escrever.
  void _openSearch(BuildContext context) {
    pendingExploreQuery.value = '';
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
    var nearby = MockData.locations.toList()
      ..sort((a, b) {
        final da = location_service.realDistanceKm(a.latitude, a.longitude) ?? a.distanceKm;
        final db = location_service.realDistanceKm(b.latitude, b.longitude) ?? b.distanceKm;
        return da.compareTo(db);
      });
    if (_selectedCategory != null) {
      nearby = nearby.where((loc) => categoryOf(loc) == _selectedCategory).toList();
    }
    final nearestTwo = nearby.take(2).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_greetingPhrase(), style: AppTextStyles.bodySmall),
          const SizedBox(height: 2),
          Text(
            signedIn ? _greetingName() : 'Bem-vindo',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 20),
          _HeroCard(onSearchTap: () => _openSearch(context)),
          const SizedBox(height: 24),
          const Text('categorias', style: AppTextStyles.label),
          const SizedBox(height: 10),
          _CategoryChips(
            selected: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _QuickLink(
                  icon: Icons.confirmation_number_outlined,
                  label: 'as minhas senhas',
                  onTap: () => goToRootTab(context, 2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _QuickLink(
                  icon: Icons.star_outline_rounded,
                  label: 'favoritos',
                  onTap: () => _openFavorites(context),
                ),
              ),
            ],
          ),
          if (signedIn) ...[
            const SizedBox(height: 26),
            ValueListenableBuilder<List<Favorite>>(
              valueListenable: favoritesStore,
              builder: (context, favorites, _) {
                final locations = favorites.map(_findLocation).whereType<QueueLocation>().take(3).toList();
                if (locations.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('os seus favoritos', style: AppTextStyles.h3),
                    const SizedBox(height: 14),
                    ...locations.map((loc) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InstitutionCard(location: loc, onTap: () => _openLocation(context, loc)),
                        )),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          Text('filas perto de si', style: AppTextStyles.h3),
          const SizedBox(height: 14),
          if (nearestTwo.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text('Sem instituições nesta categoria.', style: AppTextStyles.bodySmall),
            )
          else
            ...nearestTwo.map(
              (loc) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InstitutionCard(location: loc, onTap: () => _openLocation(context, loc)),
              ),
            ),
        ],
      ),
    );
  }
}

/// Hero de entrada (componente obrigatório #1): cartão coral claro com
/// formas orgânicas decorativas a sangrar para fora, logótipo+nome,
/// slogan fixo em 2 linhas, subtítulo neutro, e um único ponto de acção
/// (a barra de pesquisa/navegação). Texto sempre no tom mais escuro da
/// família coral (regra de contraste) -- nunca branco sobre esta cor
/// clara, e sem gradiente nenhum (superfície sólida).
class _HeroCard extends StatelessWidget {
  final VoidCallback onSearchTap;

  const _HeroCard({required this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        width: double.infinity,
        color: AppColors.primaryLight,
        child: Stack(
          children: [
            // Formas orgânicas decorativas -- verde-menta e âmbar,
            // opacidade 0.6-0.7, a sangrar para fora dos cantos.
            Positioned(
              right: -34,
              top: -34,
              child: _OrganicBlob(color: AppColors.mintLight.withValues(alpha: 0.65), size: 120),
            ),
            Positioned(
              left: -26,
              bottom: -30,
              child: _OrganicBlob(color: AppColors.amberLight.withValues(alpha: 0.6), size: 90),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.confirmation_number_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Text('Fila Certa', style: AppTextStyles.h2.copyWith(color: AppColors.onPrimaryLight)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Entre na fila.\nNão fique na fila.',
                    style: AppTextStyles.display.copyWith(color: AppColors.onPrimaryLight, fontSize: 22, height: 1.25),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Escolha um banco ou serviço público e acompanhe a sua vez sem sair de onde está.',
                    style: TextStyle(color: AppColors.onPrimaryLight.withValues(alpha: 0.75), fontSize: 12.5, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  _SearchNavBar(onTap: onSearchTap),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrganicBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _OrganicBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Ação de pesquisa/entrada única (componente obrigatório #2): um único
/// elemento com aparência de barra de pesquisa que funciona como botão
/// de navegação -- nunca duplicado por um botão separado a levar ao
/// mesmo destino. Ao tocar, muda para "Explorar" e devolve logo o foco
/// ao campo real de pesquisa, já pronto para escrever.
class _SearchNavBar extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchNavBar({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Pesquisar um serviço',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.search, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 10),
                Expanded(
                  child: Text('o que precisa de tratar?', style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary)),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Chips de categoria (componente obrigatório #3): pílulas horizontais
/// roláveis, uma cor pastel por categoria, ícone + rótulo em minúsculas,
/// sem caixa/sombra. Filtram "Filas perto de si" abaixo -- substituem os
/// antigos atalhos "Perto de mim"/"Instituições", que levavam ambos ao
/// mesmo sítio sem filtrar nada (controlos redundantes).
class _CategoryChips extends StatelessWidget {
  final InstitutionCategory? selected;
  final ValueChanged<InstitutionCategory?> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _Chip(label: 'todas', icon: Icons.apps_rounded, color: AppColors.textSecondary, background: AppColors.borderLight, selected: selected == null, onTap: () => onSelected(null)),
          const SizedBox(width: 8),
          _Chip(
            label: '${InstitutionCategory.bank.label}s',
            icon: Icons.account_balance_outlined,
            color: AppColors.onAmberMedium,
            background: AppColors.amberBg,
            selected: selected == InstitutionCategory.bank,
            onTap: () => onSelected(InstitutionCategory.bank),
          ),
          const SizedBox(width: 8),
          _Chip(
            label: 'serviços públicos',
            icon: Icons.apartment_outlined,
            color: AppColors.onMintMedium,
            background: AppColors.mintBg,
            selected: selected == InstitutionCategory.publicService,
            onTap: () => onSelected(InstitutionCategory.publicService),
          ),
        ],
      ),
    );
  }
}

/// Atalhos reais para destinos sem nenhum outro acesso na Home
/// ("senhas" já tem separador próprio, mas repetir aqui é conveniência
/// comum, não um controlo redundante para o MESMO destino da pesquisa;
/// "favoritos" não tem nenhum separador próprio).
class _QuickLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickLink({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: AppColors.border)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 17, color: AppColors.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

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
            color: selected ? color : background,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: selected ? Colors.white : color)),
            ],
          ),
        ),
      ),
    );
  }
}
