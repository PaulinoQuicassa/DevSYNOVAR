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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: service.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(service.icon, color: service.color, size: 22),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                service.name,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5, height: 1.25),
              ),
              const SizedBox(height: 4),
              Text(
                service.description,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.groups_outlined, size: 14, color: service.color),
                  const SizedBox(width: 4),
                  Text(
                    '${service.peopleInQueue} na fila',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: service.color),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.access_time, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 4),
                  Text('${service.etaMinutes} min', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
