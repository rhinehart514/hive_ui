import 'package:flutter/material.dart';
import '../../design/design_tokens.dart';

/// Applies a subtle micro-grain texture overlay to its child.
///
/// This widget is intended to be used as part of the HIVE material system
/// to add visual depth and texture to surfaces, aligning with brand_aesthetic.md.
class MicroGrainTexture extends StatelessWidget {
  final Widget child;
  final double opacity;
  final String textureAssetPath;

  /// Creates a MicroGrainTexture widget.
  ///
  /// [child]: The widget to apply the texture over.
  /// [opacity]: The opacity of the texture overlay. Defaults to `DesignTokens.opacity.microGrain` (3%).
  /// [textureAssetPath]: The path to the texture image asset.
  ///                     Defaults to 'assets/images/hivelogo.png'.
  ///                     **TODO:** Confirm this is the desired texture asset.
  const MicroGrainTexture({
    super.key,
    required this.child,
    // Allow overriding opacity, but default to the token value
    this.opacity = -1, // Use -1 as sentinel for default
    this.textureAssetPath = 'assets/images/hivelogo.png', // Updated default path
  });

  @override
  Widget build(BuildContext context) {
    final tokens = DesignTokens();
    // Use default token opacity if not overridden
    final effectiveOpacity = (opacity == -1) ? tokens.opacity.microGrain : opacity;

    // TODO: Ensure the texture asset exists at the specified path.
    // Consider pre-caching the image if performance becomes an issue.

    return RepaintBoundary(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child, // The main content
          // Texture overlay
          Positioned.fill(
            child: IgnorePointer(
              // Ignore pointer events on the texture overlay
              child: Opacity(
                opacity: effectiveOpacity,
                child: Image.asset(
                  textureAssetPath,
                  fit: BoxFit.cover, // Cover the area
                  repeat: ImageRepeat.repeat, // Tile the texture
                  // Add blend mode if needed for better integration
                  // blendMode: BlendMode.overlay, 
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 