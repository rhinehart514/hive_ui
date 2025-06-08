import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/components/buttons.dart';

/// Selection step for profile creation (class level, field of study, residence)
class SelectionSetupStep extends StatefulWidget {
  /// Title of the selection step
  final String title;

  /// Description text
  final String description;

  /// List of options to select from
  final List<String> options;

  /// Currently selected option
  final String? initialSelection;

  /// Callback when an option is selected
  final Function(String selection) onSelectionSubmitted;

  /// Constructor
  const SelectionSetupStep({
    super.key,
    required this.title,
    required this.description,
    required this.options,
    this.initialSelection,
    required this.onSelectionSubmitted,
  });

  @override
  State<SelectionSetupStep> createState() => _SelectionSetupStepState();
}

class _SelectionSetupStepState extends State<SelectionSetupStep> {
  String? _selectedOption;

  @override
  void initState() {
    super.initState();
    _selectedOption = widget.initialSelection;
  }

  void _submitSelection() {
    if (_selectedOption != null) {
      HapticFeedback.mediumImpact();
      widget.onSelectionSubmitted(_selectedOption!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
        ),
        const SizedBox(height: 24),
        _buildSelectionOptions(),
        const SizedBox(height: 24),
        HiveButton(
          text: 'Continue',
          variant: HiveButtonVariant.primary,
          size: HiveButtonSize.large,
          fullWidth: true,
          onPressed: _selectedOption != null ? _submitSelection : null,
        ),
      ],
    );
  }

  Widget _buildSelectionOptions() {
    return SizedBox(
      height: 300,
      child: ListView.builder(
        itemCount: widget.options.length,
        itemBuilder: (context, index) {
          final option = widget.options[index];
          final isSelected = _selectedOption == option;

          return _buildSelectionTile(
            option: option,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedOption = option;
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectionTile({
    required String option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? AppColors.gold : Colors.white,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.gold,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
