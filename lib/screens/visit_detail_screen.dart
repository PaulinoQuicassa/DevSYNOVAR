import 'package:flutter/material.dart';
import '../models/visit.dart';
import '../theme/app_theme.dart';
import '../widgets/bank_logo.dart';
import '../widgets/screen_header.dart';
import '../widgets/star_rating.dart';
import '../widgets/status_pill.dart';

class VisitDetailScreen extends StatelessWidget {
  final Visit visit;

  const VisitDetailScreen({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            const ScreenHeader(title: 'Detalhe do atendimento'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      BankLogo(monogram: visit.monogram, color: visit.color, size: 48),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(visit.bank, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                            const SizedBox(height: 2),
                            Text(visit.service, style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      StatusPill(label: visit.status.label, color: visit.status.color, background: visit.status.background),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: AppColors.border),
                  const SizedBox(height: 16),
                  _Row(label: 'Senha', value: visit.ticket),
                  _Row(label: 'Data', value: visit.date, isLast: visit.rating == null),
                  if (visit.rating != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('A sua avaliação', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        StarRating(value: visit.rating!, size: 16),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _Row({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
