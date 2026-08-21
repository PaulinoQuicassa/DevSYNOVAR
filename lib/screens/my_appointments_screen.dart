import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/status_pill.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  static const _history = <_HistoryItem>[
    _HistoryItem(bank: 'Banco de Poupança e Crédito (BPC)', monogram: 'BPC', color: Color(0xFF1D3F91), service: 'Atendimento Balcão', date: 'Hoje, 09:41', ticket: 'A023', status: 'Concluído', statusColor: AppColors.success, statusBg: AppColors.successBg),
    _HistoryItem(bank: 'Banco BFA', monogram: 'BFA', color: Color(0xFFE8622C), service: 'Depósitos e Levantamentos', date: 'Ontem, 15:12', ticket: 'B104', status: 'Concluído', statusColor: AppColors.success, statusBg: AppColors.successBg),
    _HistoryItem(bank: 'SIAC — Centro de Atendimento', monogram: 'SIAC', color: Color(0xFF2E7CB8), service: 'Serviços ao Cidadão', date: '14 Ago, 11:05', ticket: 'C051', status: 'Não compareceu', statusColor: AppColors.critical, statusBg: AppColors.criticalBg),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Os meus atendimentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Histórico de filas e atendimentos.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        ..._history.map(
          (item) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BankLogo(monogram: item.monogram, color: item.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.bank, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.25)),
                      const SizedBox(height: 2),
                      Text(item.service, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('${item.date}  ·  Senha ${item.ticket}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                StatusPill(label: item.status, color: item.statusColor, background: item.statusBg),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryItem {
  final String bank;
  final String monogram;
  final Color color;
  final String service;
  final String date;
  final String ticket;
  final String status;
  final Color statusColor;
  final Color statusBg;

  const _HistoryItem({
    required this.bank,
    required this.monogram,
    required this.color,
    required this.service,
    required this.date,
    required this.ticket,
    required this.status,
    required this.statusColor,
    required this.statusBg,
  });
}
