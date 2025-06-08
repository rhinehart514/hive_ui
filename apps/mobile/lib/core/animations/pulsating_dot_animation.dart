import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

class PulsatingDotAnimation extends StatelessWidget {
  final Color color;
  final double size;

  const PulsatingDotAnimation({
    super.key,
    this.color = AppColors.gold,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: Implement actual pulsating dot animation later
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
} 