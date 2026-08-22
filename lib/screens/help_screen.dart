import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme/app_theme.dart';
import '../widgets/contact_sheet.dart';
import '../widgets/gradient_button.dart';
import '../widgets/screen_header.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = <(String, String)>[
    (
      'Como entro numa fila?',
      'Na aba Início, toca em "Entrar numa fila", escolhe o local e o serviço que pretendes. A tua senha é atribuída de imediato.',
    ),
    (
      'Posso sair e voltar mais tarde?',
      'Sim. Enquanto estiveres na fila, podes fechar a app — recebes uma notificação quando estiveres quase na sua vez.',
    ),
    (
      'Como cancelo um agendamento?',
      'Na aba Agendamentos, toca no agendamento e depois em "Cancelar agendamento".',
    ),
    (
      'O que acontece se eu perder a minha vez?',
      'Se não comparecer no ecrã "É a sua vez", pode indicar "Não posso comparecer" para que outra pessoa seja chamada.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Ajuda e suporte'),
            const SizedBox(height: 12),
            const Text('Perguntas frequentes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            ..._faqs.map(
              (faq) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(faq.$2, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Não encontrou o que procurava?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
              'A nossa equipa de suporte responde todos os dias úteis, das 8h às 18h.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: 'Contactar suporte',
              icon: Icons.support_agent_outlined,
              onTap: () => showContactSheet(
                context,
                title: 'Contactar suporte',
                phone: MockData.supportPhone,
                whatsapp: MockData.supportWhatsapp,
                email: MockData.supportEmail,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
