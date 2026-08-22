import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';

Future<void> _launch(BuildContext context, Uri uri, String failureMessage) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}

void showContactSheet(
  BuildContext context, {
  required String title,
  String? phone,
  String? whatsapp,
  String? email,
}) {
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
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              if (phone != null)
                _ContactRow(
                  icon: Icons.call_outlined,
                  label: 'Ligar',
                  value: phone,
                  color: AppColors.primary,
                  onTap: () => _launch(sheetContext, Uri.parse('tel:$phone'), 'Não foi possível abrir o telefone.'),
                ),
              if (whatsapp != null)
                _ContactRow(
                  icon: Icons.chat_bubble_outline,
                  label: 'WhatsApp',
                  value: '+$whatsapp',
                  color: const Color(0xFF25D366),
                  onTap: () => _launch(sheetContext, Uri.parse('https://wa.me/$whatsapp'), 'Não foi possível abrir o WhatsApp.'),
                ),
              if (email != null)
                _ContactRow(
                  icon: Icons.mail_outline,
                  label: 'Email',
                  value: email,
                  color: AppColors.accentPurple,
                  onTap: () => _launch(sheetContext, Uri.parse('mailto:$email'), 'Não foi possível abrir o email.'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> openMapsDirections(BuildContext context, String address) async {
  final query = Uri.encodeComponent(address);
  await _launch(
    context,
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'),
    'Não foi possível abrir o mapa.',
  );
}
