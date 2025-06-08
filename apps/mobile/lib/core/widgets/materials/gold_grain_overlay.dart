import 'package:flutter/material.dart';
import '../../design/design_tokens.dart';

/// Applies a 3% transparent gold grain texture overlay.
///
/// This widget is specifically intended for the primary HIVE background canvas (#000000)
/// as defined in the HIVE brand aesthetic.
class GoldGrainOverlay extends StatelessWidget {
  final Widget child;
  final String textureAssetPath;

  /// Creates a GoldGrainOverlay widget.
  ///
  /// [child]: The widget to apply the texture over (typically the root Scaffold background).
  /// [textureAssetPath]: The path to the gold grain texture image asset.
  ///                     Defaults to 'assets/textures/gold_grain.png'.
  ///                     **TODO:** Verify and replace with the actual final asset path.
  const GoldGrainOverlay({
    super.key,
    required this.child,
    this.textureAssetPath = 'assets/textures/gold_grain.png', // Placeholder
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens();
    // Use the specific microGrain opacity token (3%) as defined for this overlay
    final double overlayOpacity = tokens.opacity.microGrain;

    // TODO: Ensure the texture asset exists at the specified path.

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child, // The main content
          // Gold Grain Texture overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Opacity(
                opacity: overlayOpacity,
                child: Image.asset(
                  textureAssetPath,
                  fit: BoxFit.cover,
                  repeat: ImageRepeat.repeat,
                  // TODO: Consider BlendMode.color or other modes if the texture isn't pre-tinted gold.
                  // blendMode: BlendMode.color,
                  // color: tokens.colors.brandGold100, // Apply gold tint if needed
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 