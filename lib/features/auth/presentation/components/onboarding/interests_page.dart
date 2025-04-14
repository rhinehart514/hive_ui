import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/app_theme.dart';
import 'package:hive_ui/features/auth/presentation/components/common/animated_continue_button.dart';
import 'package:hive_ui/features/auth/presentation/utils/animation_constants.dart';

class InterestsPage extends StatelessWidget {
  final List<String> selectedInterests;
  final List<String> interestOptions;
  final ValueChanged<String> onInterestToggle;
  final Widget progressIndicator;
  final VoidCallback? onContinue;
  final int minInterests;
  final int maxInterests;

  const InterestsPage({
    Key? key,
    required this.selectedInterests,
    required this.interestOptions,
    required this.onInterestToggle,
    required this.progressIndicator,
    this.onContinue,
    this.minInterests = 5,
    this.maxInterests = 10,
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
              'What are your interests?',
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
            child: Row(
              children: [
                Text(
                  'Pick at least $minInterests (max $maxInterests)',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: AnimationConstants.standardDuration,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedInterests.length >= minInterests
                        ? Colors.green.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${selectedInterests.length}/$maxInterests',
                    style: GoogleFonts.inter(
                      color: selectedInterests.length >= minInterests
                          ? Colors.green
                          : Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: AnimationConstants.standardDuration,
              curve: AnimationConstants.entranceCurve,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: child,
                );
              },
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(
                    interestOptions.length,
                    (index) {
                      final interest = interestOptions[index];
                      final isSelected = selectedInterests.contains(interest);
                      
                      // Staggered animation for each chip
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 350 + (index % 10) * 40), // Staggered
                        curve: AnimationConstants.entranceCurve,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: 0.8 + (0.2 * value),
                            child: Opacity(
                              opacity: value,
                              child: child,
                            ),
                          );
                        },
                        child: _buildInterestChip(interest, isSelected),
                      );
                    },
                  ),
                ),
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
              isEnabled: selectedInterests.length >= minInterests,
              onPressed: onContinue,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildInterestChip(String interest, bool isSelected) {
    return GestureDetector(
      onTap: () => onInterestToggle(interest),
      child: AnimatedContainer(
        duration: AnimationConstants.standardDuration,
        curve: AnimationConstants.standardCurve,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
              ? Colors.transparent 
              : Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Text(
          interest,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
} 