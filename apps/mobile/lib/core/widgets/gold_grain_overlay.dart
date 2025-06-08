import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/widgets/micro_grain_texture.dart';

/// A specialized texture overlay that applies a gold grain effect to its child.
/// 
/// Implements the canvas treatment described in brand_aesthetic.md Section 4.1:
/// - Primary Background (#0D0D0D) with 3% transparent gold grain texture overlay
/// 
/// This component is primarily used for the app background and can be applied 
/// to Scaffold backgrounds or other base canvas elements.
class GoldGrainOverlay extends StatelessWidget {
  /// The widget to apply the gold grain texture to
  final Widget child;
  
  /// Opacity of the grain texture (3% recommended per brand spec)
  final double opacity;
  
  /// Whether to animate the grain (subtle shifting)
  final bool animate;
  
  /// Whether to include the vertical gold glow streak
  final bool includeGlowStreak;
  
  /// Creates a widget that adds a gold grain texture overlay to its child.
  /// 
  /// The [opacity] should be around 0.03 (3%) per HIVE brand specs.
  /// Set [includeGlowStreak] to true to add a vertical gold glow streak
  /// (described in the Glass Layers section of brand_aesthetic.md).
  const GoldGrainOverlay({
    super.key,
    required this.child,
    this.opacity = 0.03, // 3% default per spec
    this.animate = false,
    this.includeGlowStreak = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = MicroGrainTexture(
      opacity: opacity,
      animate: animate,
      grainColor: AppColors.accentGold, // Use gold color for grain
      blendMode: BlendMode.softLight, // Soft blend for subtle effect
      child: child,
    );
    
    // Add the optional gold glow streak overlay if enabled
    if (includeGlowStreak) {
      result = Stack(
        children: [
          result,
          Positioned.fill(
            child: _GoldGlowStreak(opacity: opacity * 3), // Streak is more visible
          ),
        ],
      );
    }
    
    return result;
  }
}

/// A widget that creates a vertical gold glow streak overlay.
/// Used in the Glass Layers section of brand_aesthetic.md.
class _GoldGlowStreak extends StatelessWidget {
  final double opacity;
  
  const _GoldGlowStreak({
    required this.opacity,
  });
  
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: Container(
          decoration: BoxDecoration(
            // Vertical gradient fade from gold to transparent
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.accentGold.withOpacity(0.1),
                AppColors.accentGold.withOpacity(0.0),
              ],
              stops: const [0.0, 0.7], // Fade out at 70% of height
            ),
          ),
        ),
      ),
    );
  }
} 