import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/gradient_button.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  static const _appointments = <_Appointment>[
    _Appointment(bank: 'Banco BAI', monogram: 'BAI', color: Color(0xFF1E7A4C), service: 'Crédito Habitação', date: '22 Ago 2026', time: '10:30', code: 'AG-1042'),
    _Appointment(bank: 'Banco BCI', monogram: 'BCI', color: Color(0xFF15171C), service: 'Cartões', date: '25 Ago 2026', time: '14:00', code: 'AG-1077'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      children: [
        const Text('Agendamentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        const Text('Marque hora e evite esperar na fila.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 18),
        GradientButton(label: 'Novo agendamento', icon: Icons.add, onTap: () {}),
        const SizedBox(height: 24),
        const Text('Próximos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        ..._appointments.map(
          (a) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                BankLogo(monogram: a.monogram, color: a.color, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.bank, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(a.service, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.event_outlined, size: 13, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('${a.date}  ·  ${a.time}', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(a.code, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Appointment {
  final String bank;
  final String monogram;
  final Color color;
  final String service;
  final String date;
  final String time;
  final String code;

  const _Appointment({
    required this.bank,
    required this.monogram,
    required this.color,
    required this.service,
    required this.date,
    required this.time,
    required this.code,
  });
}
