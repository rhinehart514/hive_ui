import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

class GoldLinePulseAnimation extends StatelessWidget {
  final Color color;
  final double width;
  final double height;

  const GoldLinePulseAnimation({
    super.key,
    this.color = AppColors.gold,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: Implement actual gold line pulse animation later
    return Container(
      width: width,
      height: height,
      color: color,
    );
  }
} 