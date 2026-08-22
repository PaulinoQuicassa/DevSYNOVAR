import 'package:flutter/material.dart';
import '../models/service_item.dart';
import '../theme/app_theme.dart';

class ServiceCard extends StatelessWidget {
  final ServiceItem service;
  final VoidCallback onTap;

  const ServiceCard({super.key, required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: service.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(service.icon, color: service.color, size: 19),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                service.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.groups_outlined, size: 13, color: service.color),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${service.peopleInQueue} na fila',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: service.color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.access_time, size: 13, color: AppColors.textMuted),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${service.etaMinutes} min',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
