import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../theme/app_theme.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/screen_header.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _pickLanguage() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)),
                  ),
                ),
                const Text('Idioma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _LanguageOption(
                  label: 'Português (Angola)',
                  selected: appLanguageController.value == 'pt',
                  onTap: () {
                    appLanguageController.value = 'pt';
                    Navigator.of(sheetContext).pop();
                  },
                ),
                _LanguageOption(label: 'English', enabled: false, selected: false, onTap: () {}),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resetDemoData() async {
    final confirmed = await confirmAction(
      context,
      title: 'Repor dados de demonstração?',
      message: 'Os agendamentos e o histórico voltam ao estado inicial. Esta ação não pode ser desfeita.',
      confirmLabel: 'Repor',
      danger: true,
    );
    if (confirmed) {
      appointmentsStore.reset();
      historyStore.reset();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados de demonstração repostos.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Definições'),
            const SizedBox(height: 12),
            ValueListenableBuilder<String>(
              valueListenable: appLanguageController,
              builder: (context, lang, _) => _SettingsRow(
                icon: Icons.language_outlined,
                title: 'Idioma',
                value: lang == 'pt' ? 'Português (Angola)' : 'English',
                onTap: _pickLanguage,
              ),
            ),
            const _SettingsRow(
              icon: Icons.straighten_outlined,
              title: 'Unidade de distância',
              value: 'Quilómetros (km)',
            ),
            const SizedBox(height: 24),
            const Text('Dados', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: _resetDemoData,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
                  child: const Row(
                    children: [
                      Icon(Icons.restart_alt, size: 19, color: AppColors.critical),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Repor dados de demonstração',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.critical),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este protótipo não tem servidor — os agendamentos e o histórico ficam guardados apenas neste telemóvel, não sincronizam com outros dispositivos.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback? onTap;

  const _SettingsRow({required this.icon, required this.title, required this.value, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppColors.textPrimary),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
              Text(value, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 18, color: AppColors.textMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _LanguageOption({required this.label, required this.selected, required this.onTap, this.enabled = true});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 20,
                color: enabled ? (selected ? AppColors.primary : AppColors.textMuted) : AppColors.border,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                ),
              ),
              if (!enabled) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
                  child: const Text('Brevemente', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
