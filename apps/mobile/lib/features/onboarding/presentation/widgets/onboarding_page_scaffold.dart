import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
// import 'package:hive_ui/theme/app_typography.dart'; // Placeholder
// import 'package:hive_ui/theme/app_layout.dart'; // Placeholder
import 'package:flutter_animate/flutter_animate.dart';

/// A consistent scaffold structure for onboarding pages.
///
/// Provides standard padding, title, subtitle, and body arrangement
/// with HIVE styling placeholders.
class OnboardingPageScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget body;

  // Define constants locally for now
  static const double spacingSmall = 8.0;
  static const double spacingLarge = 24.0;
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0);

  /// Creates an instance of [OnboardingPageScaffold].
  const OnboardingPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    // Using Theme.of(context).textTheme for placeholders
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600); // SF Pro Display Medium 28pt Placeholder
    final subtitleStyle = textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary); // SF Pro Text Regular 17pt Placeholder

    return Padding(
      padding: pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated Title
          Text(
            title,
            style: titleStyle,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: spacingSmall),
          // Animated Subtitle
          Text(
            subtitle,
            style: subtitleStyle,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms).slideY(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOut),
          const SizedBox(height: spacingLarge),
          // Body Content (occupies remaining space)
          Expanded(
            child: body,
          ),
        ],
      ),
    );
  }
} 