import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';

class ReportFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Function(bool) onSelected;
  final IconData? icon;

  const ReportFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      showCheckmark: false,
      avatar: icon != null ? Icon(icon, size: 18) : null,
      backgroundColor: Colors.black.withOpacity(0.3),
      selectedColor: AppColors.gold.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.gold : Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppColors.gold : Colors.white.withOpacity(0.2),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
} 