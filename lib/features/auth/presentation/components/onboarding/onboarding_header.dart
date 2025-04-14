import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(1.5),
                  child: LinearProgressIndicator(
                    value: currentStep / totalSteps,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 3,
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
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        
        // Subtitle if provided
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ],
    );
  }
}
