import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/components/common/animated_selection_item.dart';
import 'package:hive_ui/features/auth/presentation/components/common/animated_continue_button.dart';
import 'package:hive_ui/features/auth/presentation/utils/animation_constants.dart';

class YearPage extends StatelessWidget {
  final String? selectedYear;
  final List<String> years;
  final ValueChanged<String> onYearSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const YearPage({
    Key? key,
    required this.selectedYear,
    required this.years,
    required this.onYearSelected,
    required this.progressIndicator,
    this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title with slight entrance animation
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AnimationConstants.standardDuration,
            curve: AnimationConstants.entranceCurve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Text(
              'What year are you?',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AnimationConstants.standardDuration,
            curve: AnimationConstants.entranceCurve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: Text(
              'Select your current year',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          // Staggered entrance of year options
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(
              years.length,
              (index) {
                final year = years[index];
                final isSelected = year == selectedYear;
                
                // Stagger the animations
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: AnimationConstants.standardDuration,
                  curve: AnimationConstants.entranceCurve,
                  // Add a delay based on index for staggered effect
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: AnimatedSelectionItem(
                    text: year,
                    isSelected: isSelected,
                    onTap: () => onYearSelected(year),
                  ),
                );
              },
            ),
          ),
          const Expanded(child: SizedBox()),
          progressIndicator,
          const SizedBox(height: 24),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: AnimationConstants.standardDuration,
            curve: AnimationConstants.entranceCurve,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: child,
              );
            },
            child: AnimatedContinueButton(
              isEnabled: selectedYear != null,
              onPressed: onContinue,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
} 