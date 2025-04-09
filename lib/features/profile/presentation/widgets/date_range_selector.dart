import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/common/widgets/glassmorphic_container.dart';

class DateRangeSelector extends StatelessWidget {
  final Function(DateTimeRange) onRangeSelected;

  const DateRangeSelector({
    super.key,
    required this.onRangeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicContainer(
      borderRadius: 12,
      padding: const EdgeInsets.all(16),
      blur: 10,
      border: 1,
      linearGradient: AppColors.glassGradient,
      borderGradient: AppColors.glassGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date Range',
            style: GoogleFonts.poppins(
              color: AppColors.gold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildPresetButton(
                context,
                'Last 7 Days',
                () => _selectPresetRange(context, 7),
              ),
              const SizedBox(width: 8),
              _buildPresetButton(
                context,
                'Last 30 Days',
                () => _selectPresetRange(context, 30),
              ),
              const SizedBox(width: 8),
              _buildPresetButton(
                context,
                'Custom',
                () => _selectCustomRange(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPresetButton(BuildContext context, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  void _selectPresetRange(BuildContext context, int days) {
    final end = DateTime.now();
    final start = end.subtract(Duration(days: days));
    onRangeSelected(DateTimeRange(start: start, end: end));
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final initialDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: initialDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.gold,
              onPrimary: Colors.white,
              surface: AppColors.grey800,
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.gold,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      onRangeSelected(pickedRange);
    }
  }
} 