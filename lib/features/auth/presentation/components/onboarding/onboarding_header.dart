import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A header component for onboarding screens
class OnboardingHeader extends StatelessWidget {
  /// Current step number in the onboarding process
  final int currentStep;

  /// Total number of steps in the onboarding process
  final int totalSteps;

  /// The title to display
  final String title;

  /// Optional subtitle to display
  final String? subtitle;

  /// Whether to show a progress indicator
  final bool showProgress;

  /// Creates an OnboardingHeader
  const OnboardingHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.title,
    this.subtitle,
    this.showProgress = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        if (showProgress) ...[
          Row(
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: currentStep / totalSteps,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],

        // Title
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),

        // Subtitle
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],

        const SizedBox(height: 24),
      ],
    );
  }
}
