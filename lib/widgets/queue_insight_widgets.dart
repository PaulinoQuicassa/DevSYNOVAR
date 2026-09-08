import 'package:flutter/material.dart';
import '../domain/queue_insights.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import 'bank_logo.dart';

/// Tempo estimado como informação PRINCIPAL, número de pessoas como
/// secundário -- secção 8 do master prompt ("18–25 min" antes de "23
/// pessoas", nunca o inverso).
class WaitTimeDisplay extends StatelessWidget {
  final int minutes;
  final int peopleInQueue;
  final bool compact;

  const WaitTimeDisplay({super.key, required this.minutes, required this.peopleInQueue, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time_filled_rounded, size: compact ? 14 : 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              '$minutes min',
              style: TextStyle(fontSize: compact ? 14 : 17, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text('$peopleInQueue pessoas', style: AppTextStyles.caption),
      ],
    );
  }
}

/// Indicador "Fila Certa Score" (secção 11) -- deixa claro no próprio
/// texto que é um indicador, não uma garantia.
class ScoreBadge extends StatelessWidget {
  final int score;

  const ScoreBadge({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final label = filaCertaScoreLabel(score);
    final color = score >= 85
        ? AppColors.success
        : score >= 70
            ? AppColors.primary
            : score >= 55
                ? AppColors.warning
                : AppColors.critical;
    return Tooltip(
      message: 'Indicador estimado a partir do tempo de espera actual — não é uma garantia.',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bolt_rounded, size: 13, color: color),
            const SizedBox(width: 4),
            Text('$score/100 · $label', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }
}

/// "Quando devo sair de casa?" (secção 9) -- só aparece quando há
/// distância real (GPS) disponível; usa sempre linguagem de estimativa,
/// nunca promete precisão (a própria estimativa de deslocação é uma
/// heurística de distância em linha recta, ver `queue_insights.dart`).
class LeaveNowCard extends StatelessWidget {
  final int waitMinutes;
  final double distanceKm;

  const LeaveNowCard({super.key, required this.waitMinutes, required this.distanceKm});

  @override
  Widget build(BuildContext context) {
    final travel = estimateTravelMinutes(distanceKm);
    final leaveIn = minutesUntilShouldLeave(waitMinutes: waitMinutes, distanceKm: distanceKm) ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(AppRadius.md)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.directions_walk_rounded, color: AppColors.success, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quando sair?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(
                  leaveIn == 0
                      ? 'Pode sair já — a deslocação estimada (~$travel min) é maior do que o tempo de espera restante.'
                      : 'Pode sair daqui a aproximadamente $leaveIn min (estimativa; pode variar).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Qual é melhor para si?" (secção 10).
class RecommendationCard extends StatelessWidget {
  final QueueLocation location;
  final String reason;

  const RecommendationCard({super.key, required this.location, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BankLogo(monogram: location.monogram, color: location.brandColor, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.star_rounded, color: AppColors.amber, size: 16),
                    SizedBox(width: 4),
                    Text('Recomendado', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5, color: AppColors.primaryDark)),
                  ],
                ),
                const SizedBox(height: 3),
                Text(location.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                const SizedBox(height: 3),
                Text(reason, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
