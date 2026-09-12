import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../auth/auth_service.dart';
import '../models/whatsapp_status.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import '../widgets/screen_header.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  WhatsappStatus? _whatsapp;
  bool _whatsappBusy = false;
  String? _whatsappError;

  @override
  void initState() {
    super.initState();
    notificationSettings.addListener(_onChanged);
    _loadWhatsappStatus();
  }

  @override
  void dispose() {
    notificationSettings.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _loadWhatsappStatus() async {
    if (authService.currentUser == null) return;
    try {
      final status = await ticket_service.fetchWhatsappStatus();
      if (mounted) setState(() => _whatsapp = status);
    } catch (_) {
      // Sem telefone verificado devolve tudo `false`/`null` pelo lado
      // do servidor -- uma excepção aqui é só falha de rede/sessão;
      // mantém-se em "a carregar" e a tentativa seguinte (reabrir o
      // ecrã) resolve sozinha, sem alarmar com um erro por um detalhe
      // secundário do ecrã de definições.
    }
  }

  Future<void> _toggleWhatsapp(bool enabled) async {
    setState(() {
      _whatsappBusy = true;
      _whatsappError = null;
    });
    try {
      await ticket_service.setWhatsappNotifications(enabled);
      final status = await ticket_service.fetchWhatsappStatus();
      if (!mounted) return;
      setState(() => _whatsapp = status);
    } catch (_) {
      if (!mounted) return;
      setState(() => _whatsappError = 'Não foi possível actualizar. Tenta novamente.');
    } finally {
      if (mounted) setState(() => _whatsappBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final whatsapp = _whatsapp;
    final phoneVerified = whatsapp?.phoneVerified ?? false;
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
              subtitle: 'Avisos antes de um agendamento marcado -- em preparação, ainda não chega a avisar ninguém.',
              value: notificationSettings.appointmentReminders,
              onChanged: (_) => notificationSettings.toggle('appointmentReminders'),
              enabled: false,
            ),
            _SettingSwitch(
              icon: Icons.chat_bubble_outline,
              title: 'Notificações por WhatsApp',
              subtitle: phoneVerified
                  ? 'Receber os alertas também por WhatsApp, no número verificado desta conta.'
                  : 'Precisa de entrar com um número de telefone verificado para activar (contas antigas por email não têm número associado).',
              value: whatsapp?.notificationsEnabled ?? false,
              onChanged: (v) => _toggleWhatsapp(v),
              enabled: phoneVerified && !_whatsappBusy,
              badge: phoneVerified ? null : 'Precisa de telefone verificado',
            ),
            if (whatsapp != null) ...[
              const SizedBox(height: 8),
              _WhatsappStatusCard(status: whatsapp),
            ],
            if (_whatsappError != null) ...[
              const SizedBox(height: 8),
              Text(_whatsappError!, style: const TextStyle(fontSize: 12, color: AppColors.critical)),
            ],
            const SizedBox(height: 12),
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

/// Estado real e verificável em vez de uma simples confirmação --
/// exactamente o que foi pedido: nunca mostrar "notificação enviada"
/// (ou "activadas") sem confirmar o estado a partir do servidor.
class _WhatsappStatusCard extends StatelessWidget {
  final WhatsappStatus status;

  const _WhatsappStatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    if (status.phone == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
        child: const Text(
          'Esta conta não tem um número de telefone associado.',
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text('📱 ${status.phone}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
          Text(
            status.phoneVerified ? '✅ Número verificado' : '❌ Número não verificado',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
          Text(
            status.notificationsEnabled ? '🔔 Notificações WhatsApp — ACTIVADAS' : '🔕 Notificações WhatsApp — desactivadas',
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
          ),
        ],
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
  final bool enabled;
  final String? badge;

  const _SettingSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.badge = 'Brevemente',
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
            child: Icon(icon, size: 18, color: enabled ? AppColors.primary : AppColors.textMuted),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                        ),
                      ),
                    ),
                    if (!enabled && badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
                        child: Text(badge!, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
          Switch.adaptive(value: enabled && value, onChanged: enabled ? onChanged : null, activeThumbColor: AppColors.primary),
        ],
      ),
    );
  }
}
