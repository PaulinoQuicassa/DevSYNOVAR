import 'package:flutter/material.dart';
import '../app_stores.dart';
import '../models/visit.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/status_pill.dart';
import 'visit_detail_screen.dart';

class MyAppointmentsScreen extends StatelessWidget {
  const MyAppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<Visit>>(
      valueListenable: historyStore,
      builder: (context, history, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          children: [
            const Text('Os meus atendimentos', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Histórico de filas e atendimentos.', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 20),
            if (history.isEmpty)
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
                    Icon(Icons.history, color: AppColors.textMuted, size: 32),
                    SizedBox(height: 10),
                    Text('Ainda sem atendimentos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                  ],
                ),
              )
            else
              ...history.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => VisitDetailScreen(visit: item)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
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
                            StatusPill(label: item.status.label, color: item.status.color, background: item.status.background),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
