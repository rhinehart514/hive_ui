import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/components/common/animated_continue_button.dart';
import 'package:hive_ui/features/auth/presentation/utils/animation_constants.dart';

class FieldPage extends StatelessWidget {
  final String? selectedMajor;
  final List<String> filteredFields;
  final ValueChanged<String> onMajorSelected;
  final Widget progressIndicator;
  final VoidCallback? onContinue;

  const FieldPage({
    Key? key,
    required this.selectedMajor,
    required this.filteredFields,
    required this.onMajorSelected,
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
          // Title with entrance animation
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
              'What\'s your major/field?',
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
              'Choose your primary field of study',
              style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: AnimatedSwitcher(
              duration: AnimationConstants.standardDuration,
              switchInCurve: AnimationConstants.entranceCurve,
              switchOutCurve: AnimationConstants.exitCurve,
              child: ListView.builder(
                key: ValueKey<int>(filteredFields.length),
                itemCount: filteredFields.length,
                itemBuilder: (context, index) {
                  final field = filteredFields[index];
                  final isSelected = field == selectedMajor;
                  
                  // Staggered entrance animation
                  return TweenAnimationBuilder<double>(
                    key: ValueKey<String>(field),
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
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildFieldItem(field, isSelected),
                    ),
                  );
                },
              ),
            ),
          ),
          progressIndicator,
          const SizedBox(height: 16),
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
              isEnabled: selectedMajor != null,
              onPressed: onContinue,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildFieldItem(String field, bool isSelected) {
    return GestureDetector(
      onTap: () => onMajorSelected(field),
      child: AnimatedContainer(
        duration: AnimationConstants.standardDuration,
        curve: AnimationConstants.standardCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected 
              ? Colors.transparent 
              : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                field,
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
            if (isSelected)
              AnimatedOpacity(
                duration: AnimationConstants.quickDuration,
                opacity: isSelected ? 1.0 : 0.0,
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.black,
                  size: 20,
                ),
              ),
          ],
        ),
      ),
    );
  }
} 