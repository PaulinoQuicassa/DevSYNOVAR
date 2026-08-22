import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  @override
  void initState() {
    super.initState();
    notificationSettings.addListener(_onChanged);
  }

  @override
  void dispose() {
    notificationSettings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Notificações'),
            const SizedBox(height: 12),
            _SettingSwitch(
              icon: Icons.confirmation_number_outlined,
              title: 'Alertas de fila',
              subtitle: 'Avisos quando estiver quase na sua vez ou for chamado.',
              value: notificationSettings.queueAlerts,
              onChanged: (_) => notificationSettings.toggle('queueAlerts'),
            ),
            _SettingSwitch(
              icon: Icons.event_available_outlined,
              title: 'Lembretes de agendamento',
              subtitle: 'Avisos antes de um agendamento marcado.',
              value: notificationSettings.appointmentReminders,
              onChanged: (_) => notificationSettings.toggle('appointmentReminders'),
            ),
            _SettingSwitch(
              icon: Icons.chat_bubble_outline,
              title: 'Notificações por WhatsApp',
              subtitle: 'Receber os alertas também por WhatsApp, além da app.',
              value: notificationSettings.whatsapp,
              onChanged: (_) => notificationSettings.toggle('whatsapp'),
            ),
            _SettingSwitch(
              icon: Icons.campaign_outlined,
              title: 'Novidades e promoções',
              subtitle: 'Comunicações sobre novos serviços e parceiros.',
              value: notificationSettings.promotions,
              onChanged: (_) => notificationSettings.toggle('promotions'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }
}
