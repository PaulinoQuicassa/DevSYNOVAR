import 'package:flutter/material.dart';
import '../app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import 'about_screen.dart';
import 'help_screen.dart';
import 'notification_settings_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Terminar sessão?',
      message: 'Vais precisar de entrar novamente para veres os teus agendamentos e histórico.',
      confirmLabel: 'Terminar sessão',
      danger: true,
    );
    if (confirmed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessão terminada.')),
      );
      goToRootTab(context, 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Perfil', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: AppColors.heroGradient,
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Paulino Quicassa', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                    SizedBox(height: 3),
                    Text('paulino.quicassa@hotmail.com', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('Conta'),
        _ProfileRow(
          icon: Icons.notifications_none_rounded,
          label: 'Notificações',
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
        ),
        _ProfileRow(
          icon: Icons.tune,
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
        const SizedBox(height: 20),
        _ProfileRow(
          icon: Icons.logout,
          label: 'Terminar sessão',
          danger: true,
          onTap: () => _signOut(context),
        ),
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

  const _ProfileRow({required this.icon, required this.label, required this.onTap, this.danger = false});

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
              const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
