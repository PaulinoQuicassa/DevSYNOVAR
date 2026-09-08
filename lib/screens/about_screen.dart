import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/screen_header.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Sobre a Fila Certa'),
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.confirmation_number_outlined, color: Colors.white, size: 32),
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: Text('Fila Certa', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
            const SizedBox(height: 4),
            const Center(child: Text('Versão 1.0.0', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'A Fila Certa ajuda-o a entrar numa fila sem ter de ficar fisicamente nela. Escolha o banco ou serviço, acompanhe a sua posição em tempo real e seja avisado quando estiver quase na sua vez.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            const _InfoRow(label: 'Mercado', value: 'Angola'),
            const _InfoRow(label: 'Plataforma', value: 'Flutter'),
            const _InfoRow(label: 'Tipo', value: 'Protótipo de demonstração'),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
