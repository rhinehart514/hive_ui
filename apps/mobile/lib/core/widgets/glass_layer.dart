import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ui/core/theme/app_colors.dart';
import 'package:hive_ui/core/theme/animation_durations.dart';
import 'package:hive_ui/core/widgets/gold_grain_overlay.dart';

/// A glass layer overlay that creates a frosted glass effect.
/// 
/// Implements the glass layer specs from brand_aesthetic.md Section 4.1:
/// - Blur: 20pt
/// - Tint: rgba(13, 13, 13, 0.8)
/// - Optional gold glow streak overlay
/// - Z-zoom animation for entrance/exit (if animated)
class GlassLayer extends StatelessWidget {
  /// Child widget to display on top of the glass layer
  final Widget child;
  
  /// Background blur amount (20pt default per HIVE specs)
  final double blurAmount;
  
  /// Background tint opacity (0.8 default per HIVE specs)
  final double tintOpacity;
  
  /// Whether to add a gold streak overlay
  final bool showGoldStreak;
  
  /// Optional background dimming amount (0.5 default per HIVE specs for modals)
  final double? backgroundDim;
  
  /// Whether the layer has rounded corners
  final BorderRadius? borderRadius;
  
  /// Whether the glass effect should animate in (for modals)
  final bool animateEntrance;
  
  /// Creates a glass layer overlay with blur and tint effects.
  /// 
  /// The [blurAmount] defaults to 20pt as specified in the HIVE brand aesthetic guidelines.
  /// The [tintOpacity] defaults to 0.8 as specified (rgba(13, 13, 13, 0.8)).
  const GlassLayer({
    super.key,
    required this.child,
    this.blurAmount = 20.0,
    this.tintOpacity = 0.8,
    this.showGoldStreak = false,
    this.backgroundDim,
    this.borderRadius,
    this.animateEntrance = false,
  });

  @override
  Widget build(BuildContext context) {
    final animationDurations = Theme.of(context).extension<AnimationDurations>() ?? 
                             const AnimationDurations();
    
    // Build the glass effect
    Widget glassCore = BackdropFilter(
      filter: ImageFilter.blur(
        sigmaX: blurAmount,
        sigmaY: blurAmount,
      ),
      // The actual tinted container + child goes INSIDE the BackdropFilter
      child: Container(
        decoration: BoxDecoration(
          // Replace flat color with a subtle gradient for glossiness
          // color: AppColors.primaryBackground.withOpacity(tintOpacity),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              // Slightly lighter tint at the top-left
              AppColors.primaryBackground.withOpacity(tintOpacity + 0.05), 
              // Standard tint at the bottom-right
              AppColors.primaryBackground.withOpacity(tintOpacity), 
            ],
            stops: const [0.1, 0.9], // Adjust stops for desired gradient spread
          ),
          borderRadius: borderRadius, 
        ),
        child: child,
      ),
    );

    // Apply clipping AFTER the BackdropFilter
    Widget clippedGlass = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: glassCore,
    );

    // Add optional layers (dim, streak) around the clipped glass
    Widget glassEffect = Stack(
      alignment: Alignment.center, // Align layers
      children: [
        // Optional background dim (Rendered first, behind everything)
        if (backgroundDim != null)
          Positioned.fill(
            child: Container(
              // Apply borderRadius here too if dim should be clipped
              decoration: BoxDecoration(
              color: Colors.black.withOpacity(backgroundDim!),
                 borderRadius: borderRadius,
              ),
            ),
          ),
          
        // The main clipped glass effect (blur + tint + child)
        clippedGlass,
        
        // Optional gold glow streak (Rendered last, on top)
        if (showGoldStreak)
           // Use IgnorePointer to ensure streak doesn't block interaction with child
          IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius, // Match clipping
              ),
              clipBehavior: Clip.antiAlias, // Ensure streak respects rounded corners
              child: _GoldStreakOverlay(), 
          ),
        ),
        
         // Optional: Render sharp border outside the clip 
         if (borderRadius != null)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
                border: Border.all(
                  // Increase opacity slightly for sharper definition
                  color: AppColors.textPrimary.withOpacity(0.1), // Was 0.05
                  width: 0.75, // Slightly increased width
                ),
              ),
            ),
          ),
      ],
    );
    
    // Add entrance animation if requested
    if (animateEntrance) {
      return AnimatedZoomTransition(
        duration: animationDurations.contentSlide,
        curve: AnimationCurves.contentSlide,
        child: glassEffect,
      );
    }
    
    return glassEffect;
  }
}

/// A custom widget to create the gold streak overlay effect.
class _GoldStreakOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: GoldGrainOverlay(
        opacity: 0.02, // Very subtle
        includeGlowStreak: true,
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

/// Animated entrance transition for glass layers with Z-zoom effect.
class AnimatedZoomTransition extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  
  const AnimatedZoomTransition({
    super.key,
    required this.child,
    required this.duration,
    required this.curve,
  });

  @override
  State<AnimatedZoomTransition> createState() => _AnimatedZoomTransitionState();
}

class _AnimatedZoomTransitionState extends State<AnimatedZoomTransition> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  
  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.6, curve: widget.curve),
    ));
    
    _controller.forward();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          ),
        );
      },
    );
  }
} 