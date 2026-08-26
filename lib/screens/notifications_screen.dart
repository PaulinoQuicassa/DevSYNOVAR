import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../models/app_notification.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Abrir a lista conta como "ler" tudo — mesma convenção de qualquer
    // centro de notificações.
    notificationsStore.markAllRead();
  }

  String _timeLabel(DateTime? dt) {
    if (dt == null) return '';
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '${dt.day}/${dt.month} $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ValueListenableBuilder<List<AppNotification>>(
          valueListenable: notificationsStore,
          builder: (context, items, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                const ScreenHeader(title: 'Notificações', subtitle: 'Tudo o que o balcão fez sobre as suas senhas.'),
                const SizedBox(height: 16),
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.notifications_none_rounded, color: AppColors.textMuted, size: 32),
                        SizedBox(height: 10),
                        Text('Ainda sem notificações', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      ],
                    ),
                  )
                else
                  ...items.map(
                    (n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: n.read ? AppColors.border : AppColors.primary),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: n.read ? AppColors.background : AppColors.primaryTint,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.notifications_active_outlined, size: 18, color: n.read ? AppColors.textMuted : AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(n.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                                const SizedBox(height: 2),
                                Text(n.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 4),
                                Text(_timeLabel(n.createdAt), style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
