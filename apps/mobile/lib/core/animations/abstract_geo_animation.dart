import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

class AbstractGeometricAnimation extends StatelessWidget {
  final Color color;
  final double size;

  const AbstractGeometricAnimation({
    super.key,
    this.color = AppColors.gold,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    // Placeholder: Implement actual abstract geometric animation later
    return SizedBox(
      width: size,
      height: size,
      child: Icon(Icons.hexagon_outlined, color: color, size: size),
    );
  }
} 