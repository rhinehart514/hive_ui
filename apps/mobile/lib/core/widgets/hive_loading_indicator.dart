import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // Using a package for some variations
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/animations/pulsating_dot_animation.dart';
import 'package:hive_ui/core/animations/expanding_rings_animation.dart';
import 'package:hive_ui/core/animations/gold_line_pulse_animation.dart';
import 'package:hive_ui/core/animations/abstract_geo_animation.dart';

// Enum to define the different loading indicator styles
enum HiveLoadingStyle {
  goldSpinner, // Standard spinner with gold color
  pulsatingGoldDot, // Single pulsating dot
  goldArcSpinner, // Rotating arc
  expandingRings, // Expanding/collapsing rings
  subtleGrainShift, // Placeholder for texture shift + text (visual only here)
  skeletonBox, // Simple rectangular skeleton placeholder
  goldLinePulse, // Horizontal pulsing line
  shimmerBox, // Placeholder box with shimmer effect
  abstractGeometric, // Custom geometric animation
  dotsWave, // Wave animation with dots
}

/// A loading indicator widget adhering to HIVE's brand aesthetic.
///
/// Provides multiple styles controlled by the [style] parameter.
class HiveLoadingIndicator extends StatelessWidget {
  final HiveLoadingStyle style;
  final double size;
  final String? loadingText; // Optional text for styles like subtleGrainShift

  const HiveLoadingIndicator({
    super.key,
    this.style = HiveLoadingStyle.goldSpinner,
    this.size = 40.0,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case HiveLoadingStyle.goldSpinner:
        return SpinKitFadingCircle( // Simple, common spinner
          color: AppColors.accentGold,
          size: size,
        );
      case HiveLoadingStyle.pulsatingGoldDot:
        return PulsatingDotAnimation( // Custom subtle pulse
          color: AppColors.accentGold,
          size: size * 0.8, // Slightly smaller for subtlety
        );
      case HiveLoadingStyle.goldArcSpinner:
        return SpinKitRing( // Ring/Arc style
          color: AppColors.accentGold,
          size: size,
          lineWidth: size * 0.1, // Proportional line width
        );
      case HiveLoadingStyle.expandingRings:
        return ExpandingRingsAnimation( // Custom geometric expansion
          color: AppColors.accentGold,
          size: size,
        );
      case HiveLoadingStyle.subtleGrainShift:
        // Placeholder: Actual grain shift needs background integration.
        // This shows text + a minimal indicator.
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpinKitPulse(color: AppColors.accentGold.withOpacity(0.6), size: size * 0.5),
            if (loadingText != null) const SizedBox(height: 8),
            if (loadingText != null)
              Text(
                loadingText!,
                style: TextStyle(color: AppColors.textSecondary, fontSize: size * 0.35),
              ),
          ],
        );
      case HiveLoadingStyle.skeletonBox:
        // Simple representation, real skeleton loaders are more complex
        return Container(
          width: size * 2,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.surfaceCard.withOpacity(0.5),
            borderRadius: BorderRadius.circular(size * 0.1),
          ),
        );
      case HiveLoadingStyle.goldLinePulse:
        return GoldLinePulseAnimation( // Custom horizontal pulse
          color: AppColors.accentGold,
          width: size * 1.5,
          height: size * 0.1,
        );
      case HiveLoadingStyle.shimmerBox:
        // Basic shimmer placeholder - real implementation often uses shader masks
        return Container( // Placeholder for shimmer effect
             width: size * 2,
             height: size,
             decoration: BoxDecoration(
               gradient: LinearGradient(
                 colors: [
                   AppColors.surfaceCard.withOpacity(0.3),
                   AppColors.surfaceCard.withOpacity(0.6),
                   AppColors.surfaceCard.withOpacity(0.3),
                 ],
                 stops: const [0.4, 0.5, 0.6], // Simplified shimmer look
                 begin: Alignment.centerLeft,
                 end: Alignment.centerRight,
               ),
               borderRadius: BorderRadius.circular(size * 0.1),
             ),
           );
      case HiveLoadingStyle.abstractGeometric:
        return AbstractGeometricAnimation( // Custom abstract animation
          color: AppColors.accentGold,
          size: size,
        );
      case HiveLoadingStyle.dotsWave:
        return SpinKitWave( // Another subtle option
          color: AppColors.accentGold,
          size: size * 0.8,
          itemCount: 5,
        );
    }
  }
}

// NOTE: Several custom animation widgets are referenced here:
// - PulsatingDotAnimation
// - ExpandingRingsAnimation
// - GoldLinePulseAnimation
// - AbstractGeometricAnimation
// These need to be created in the `lib/core/animations/` directory.
// Also, flutter_spinkit needs to be added to pubspec.yaml. 