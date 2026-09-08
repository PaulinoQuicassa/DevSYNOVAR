import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../auth/require_auth.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import 'about_screen.dart';
import 'favorites_screen.dart';
import 'help_screen.dart';
import 'login_screen.dart';
import 'notification_settings_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = authService.userChanges.listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Terminar sessão?',
      message: 'Vais precisar de entrar novamente para veres os teus agendamentos e histórico.',
      confirmLabel: 'Terminar sessão',
      danger: true,
    );
    if (confirmed) {
      await authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    final signedIn = user != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        Text('Perfil', style: AppTextStyles.h1),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), shape: BoxShape.circle),
                child: const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(signedIn ? 'A minha conta' : 'Ainda não tem conta',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 3),
                    Text(
                      signedIn ? (user.email ?? '') : 'Entre para guardar favoritos, histórico e notificações.',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!signedIn)
                TextButton(
                  style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                  onPressed: () => Navigator.of(context, rootNavigator: true)
                      .push(MaterialPageRoute(builder: (_) => const LoginScreen())),
                  child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Conta'),
        _ProfileRow(
          icon: Icons.star_outline_rounded,
          label: 'Favoritos',
          onTap: () async {
            final ok = await requireAuth(context, reason: 'Precisa de uma conta para guardar favoritos.');
            if (ok && context.mounted) {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FavoritesScreen()));
            }
          },
        ),
        // Único ponto de acesso às notificações da app (secção 18 do
        // redesign) -- de propósito sem atalho na Home: só chega a esta
        // caixa de entrada quem tem conta e está no Perfil.
        ValueListenableBuilder<List<AppNotification>>(
          valueListenable: notificationsStore,
          builder: (context, notifications, _) {
            final unread = signedIn ? notifications.where((n) => !n.read).length : 0;
            return _ProfileRow(
              icon: Icons.notifications_none_rounded,
              label: 'Notificações',
              badge: unread > 0 ? unread : null,
              onTap: () async {
                final ok = await requireAuth(context, reason: 'Precisa de uma conta para ver as suas notificações.');
                if (ok && context.mounted) {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
                }
              },
            );
          },
        ),
        _ProfileRow(
          icon: Icons.tune,
          label: 'Preferências de notificações',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
        ),
        _ProfileRow(
          icon: Icons.settings_outlined,
          label: 'Definições',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Suporte'),
        _ProfileRow(
          icon: Icons.help_outline,
          label: 'Ajuda e suporte',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HelpScreen())),
        ),
        _ProfileRow(
          icon: Icons.info_outline,
          label: 'Sobre a Fila Certa',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen())),
        ),
        if (signedIn) ...[
          const SizedBox(height: 20),
          _ProfileRow(
            icon: Icons.logout,
            label: 'Terminar sessão',
            danger: true,
            onTap: () => _signOut(context),
          ),
        ],
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.6),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;
  final int? badge;

  const _ProfileRow({required this.icon, required this.label, required this.onTap, this.danger = false, this.badge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Icon(icon, size: 19, color: danger ? AppColors.critical : AppColors.textPrimary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: danger ? AppColors.critical : AppColors.textPrimary),
                ),
              ),
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.critical, borderRadius: BorderRadius.circular(999)),
                  child: Text(
                    badge! > 9 ? '9+' : '$badge',
                    style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
