import 'package:flutter/material.dart';
import '../location_service.dart' as location_service;
import '../models/queue_location.dart';
import '../theme/app_theme.dart';
import '../ticket_service.dart' as ticket_service;
import 'bank_logo.dart';
import 'status_pill.dart';

class LocationCard extends StatelessWidget {
  final QueueLocation location;
  final VoidCallback onTap;

  const LocationCard({super.key, required this.location, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BankLogo(monogram: location.monogram, color: location.brandColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, height: 1.25),
                    ),
                    const SizedBox(height: 2),
                    Text(location.subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            location.address,
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ValueListenableBuilder(
                          valueListenable: location_service.currentPosition,
                          builder: (context, _, __) {
                            final realKm = location_service.realDistanceKm(location.latitude, location.longitude);
                            final label = realKm != null
                                ? (realKm < 1 ? '${(realKm * 1000).round()} m' : '${realKm.toStringAsFixed(1)} km')
                                : location.distance;
                            return Text(
                              label,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (location.institutionId != null)
                          const StatusPill(
                            label: 'Piloto ao vivo',
                            color: Color(0xFF0F766E),
                            background: Color(0xFFCCFBF1),
                            icon: Icons.podcasts,
                          ),
                        if (location.institutionId != null && location.branchId != null)
                          StreamBuilder<int>(
                            stream: ticket_service.subscribeQueueSize(location.institutionId!, location.branchId!),
                            builder: (context, snapshot) => StatusPill(
                              label: '${snapshot.data ?? 0} pessoas na fila',
                              color: location.load.color,
                              background: location.load.bgColor,
                            ),
                          )
                        else
                          StatusPill(
                            label: '${location.peopleInQueue} pessoas na fila',
                            color: location.load.color,
                            background: location.load.bgColor,
                          ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                            const SizedBox(width: 3),
                            Text(
                              '${location.etaMinutes} min',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
