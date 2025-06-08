import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A dropdown field component for onboarding screens
class OnboardingDropdownField extends StatelessWidget {
  /// The currently selected value
  final String? selectedValue;

  /// The list of options to select from
  final List<String> options;

  /// Label text for the field
  final String label;

  /// Hint text when no value is selected
  final String hint;

  /// Icon to display
  final IconData icon;

  /// Callback when value changes
  final Function(String?) onChanged;

  /// Creates an OnboardingDropdownField
  const OnboardingDropdownField({
    super.key,
    required this.selectedValue,
    required this.options,
    required this.label,
    required this.hint,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selectedValue != null
                  ? AppColors.gold.withOpacity(0.5)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Row(
                children: [
                  Icon(icon, color: Colors.white54, size: 20),
                  const SizedBox(width: 12),
                  Text(
                    hint,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
              isExpanded: true,
              dropdownColor: Colors.grey[900],
              style: const TextStyle(color: Colors.white),
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white70, size: 20),
                      const SizedBox(width: 12),
                      Text(option),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
