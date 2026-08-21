import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ScreenHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? trailingIcon;
  final VoidCallback? onTrailing;
  final VoidCallback? onBack;
  final bool showBack;
  final bool trailingHasDot;

  const ScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailingIcon,
    this.onTrailing,
    this.onBack,
    this.showBack = true,
    this.trailingHasDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showBack)
            _RoundIconButton(icon: Icons.arrow_back, onTap: onBack ?? () => Navigator.of(context).pop())
          else
            const SizedBox(width: 40),
          Expanded(
            child: Column(
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (trailingIcon != null)
            _RoundIconButton(icon: trailingIcon!, onTap: onTrailing, hasDot: trailingHasDot)
          else
            const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool hasDot;

  const _RoundIconButton({required this.icon, this.onTap, this.hasDot = false});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, size: 18, color: AppColors.textPrimary)),
            if (hasDot)
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: AppColors.critical, shape: BoxShape.circle),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
