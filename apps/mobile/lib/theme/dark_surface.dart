import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:hive_ui/theme/texture_overlay.dart';

/// Surface types for HIVE dark surfaces as specified in the brand aesthetic.
enum SurfaceType {
  /// Primary background (#0D0D0D)
  canvas,
  
  /// Secondary surface (#1E1E1E to #2A2A2A gradient)
  surface,
  
  /// Elevated card (transparent black with subtle inner glow)
  elevatedCard,
  
  /// Glass layer (blur + tint)
  glass
}

/// A widget that applies the HIVE brand aesthetic for dark surfaces.
/// 
/// Implements the surface specifications from the brand aesthetic guidelines:
/// - Canvas: #0D0D0D with optional 3% transparent gold grain texture
/// - Surface: #1E1E1E to #2A2A2A gradient with soft directional lighting
/// - Elevated Card: Transparent black with subtle inner glow + drop shadow
/// - Glass Layers: Blur + tint + optional gold overlay
class DarkSurface extends StatelessWidget {
  /// The widget to display inside the surface.
  final Widget child;
  
  /// The type of surface to display.
  final SurfaceType surfaceType;
  
  /// Whether to apply the grain texture overlay.
  final bool withGrainTexture;
  
  /// Whether to animate the grain texture (for empty states).
  final bool animateGrain;
  
  /// The border radius of the surface.
  final BorderRadius? borderRadius;
  
  /// Optional elevation for shadows (0-6).
  final double elevation;
  
  /// Optional border on the surface.
  final Border? border;
  
  /// Optional padding inside the surface.
  final EdgeInsetsGeometry? padding;
  
  /// Whether to apply a gold streak overlay (for glass layers).
  final bool withGoldStreak;
  
  /// Creates a surface following HIVE brand aesthetic guidelines.
  const DarkSurface({
    super.key,
    required this.child,
    this.surfaceType = SurfaceType.surface,
    this.withGrainTexture = true,
    this.animateGrain = false,
    this.borderRadius,
    this.elevation = 0,
    this.border,
    this.padding,
    this.withGoldStreak = false,
  }) : assert(elevation >= 0 && elevation <= 6, 'Elevation must be between 0 and 6');

  @override
  Widget build(BuildContext context) {
    // Wrap content in padding if specified
    Widget content = padding != null 
      ? Padding(padding: padding!, child: child)
      : child;
    
    // Apply grain texture if needed
    if (withGrainTexture) {
      content = TextureOverlay(
        opacity: surfaceType == SurfaceType.canvas ? 0.03 : 0.02, 
        animate: animateGrain,
        color: Colors.white,
        child: content,
      );
    }
    
    // Apply gold streak for glass layers if needed
    if (withGoldStreak && surfaceType == SurfaceType.glass) {
      content = Stack(
        children: [
          content,
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x1AFFD700), // Gold with 10% opacity
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.5],
                  ),
                  borderRadius: borderRadius,
                ),
              ),
            ),
          ),
        ],
      );
    }
    
    // Apply surface styling based on type
    switch (surfaceType) {
      case SurfaceType.canvas:
        return Container(
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: borderRadius,
            border: border,
          ),
          child: content,
        );
        
      case SurfaceType.surface:
        return Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1E1E1E), // Secondary surface start
                Color(0xFF2A2A2A), // Secondary surface end
              ],
            ),
            borderRadius: borderRadius,
            border: border,
            boxShadow: elevation > 0 ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: elevation * 2,
                offset: Offset(0, elevation),
              ),
            ] : null,
          ),
          child: content,
        );
        
      case SurfaceType.elevatedCard:
        return Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: borderRadius,
            border: border ?? Border.all(
              color: Colors.white.withOpacity(0.06),
              width: 0.5,
            ),
            boxShadow: [
              // Inner glow
              BoxShadow(
                color: Colors.white.withOpacity(0.03),
                blurRadius: 8,
                spreadRadius: -2,
              ),
              // Subtle outer shadow
              if (elevation > 0) BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: elevation * 2,
                offset: Offset(0, elevation),
              ),
            ],
          ),
          child: content,
        );
        
      case SurfaceType.glass:
        return ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.dark.withOpacity(0.8),
                borderRadius: borderRadius,
                border: border,
              ),
              child: content,
            ),
          ),
        );
    }
  }
} 