import 'package:flutter/material.dart';
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import 'bank_logo.dart';

class LocationSummaryCard extends StatelessWidget {
  final QueueLocation location;
  final Widget? trailing;
  final String? tag;

  const LocationSummaryCard({super.key, required this.location, this.trailing, this.tag});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BankLogo(monogram: location.monogram, color: location.brandColor, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, height: 1.25)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        location.subtitle,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (tag != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(999)),
                    child: Text(
                      tag!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
