import 'package:flutter/material.dart';
import '../../core/app_colors.dart';

class StarRating extends StatelessWidget {
  final double rating;
  final int reviewsCount;
  final double size;
  final bool showCount;

  const StarRating({
    super.key,
    required this.rating,
    this.reviewsCount = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final fill = rating - i;
          IconData icon;
          if (fill >= 1) {
            icon = Icons.star;
          } else if (fill > 0) {
            icon = Icons.star_half;
          } else {
            icon = Icons.star_border;
          }
          return Icon(icon, size: size, color: AppColors.warning);
        }),
        if (showCount && reviewsCount > 0) ...[
          const SizedBox(width: 4),
          Text('($reviewsCount)', style: TextStyle(fontSize: size - 2, color: AppColors.textSecondary)),
        ],
      ],
    );
  }
}
