import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StarRating extends StatelessWidget {
  final int value;
  final int max;
  final double size;
  final ValueChanged<int>? onChanged;

  const StarRating({
    super.key,
    required this.value,
    this.max = 5,
    this.size = 34,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < value;
        final star = Icon(
          filled ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: filled ? AppColors.amber : const Color(0xFFD1D5DB),
        );
        if (onChanged == null) return star;
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged!(i + 1),
          child: Padding(padding: const EdgeInsets.all(2), child: star),
        );
      }),
    );
  }
}
