import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

class ExpandingRingsAnimation extends StatelessWidget {
  final Color color;
  final double size;

  const ExpandingRingsAnimation({
    super.key,
    this.color = AppColors.gold,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: Implement actual expanding rings animation later
    return SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.donut_large, color: color, size: size),
    );
  }
} 