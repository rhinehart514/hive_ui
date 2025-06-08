import 'dart:math';
import 'package:flutter/material.dart';

/// A widget that adds a subtle grain texture overlay to its child.
/// 
/// Implements the micro-grain texture described in brand_aesthetic.md Section 4.2:
/// - Consistent micro-grain texture (2-5% opacity)
/// - Organic feel through subtle noise pattern
/// - Optional subtle animation for empty states
class MicroGrainTexture extends StatefulWidget {
  /// The widget to apply the grain texture to
  final Widget child;
  
  /// Opacity of the grain texture (2-5% recommended per brand spec)
  final double opacity;
  
  /// Whether to animate the grain (subtle shifting for empty states)
  final bool animate;
  
  /// Color of the grain texture (defaults to white)
  final Color grainColor;
  
  /// Blend mode for the grain (defaults to softLight for subtle effect)
  final BlendMode blendMode;
  
  /// Creates a widget with a subtle grain texture overlay on its child.
  /// 
  /// The [opacity] should be between 0.02 and 0.05 (2-5%) per HIVE brand specs.
  /// Set [animate] to true for empty states that need subtle background animation.
  const MicroGrainTexture({
    super.key,
    required this.child,
    this.opacity = 0.03, // 3% default per spec
    this.animate = false,
    this.grainColor = Colors.white,
    this.blendMode = BlendMode.softLight,
  });

  @override
  State<MicroGrainTexture> createState() => _MicroGrainTextureState();
}

class _MicroGrainTextureState extends State<MicroGrainTexture> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  // Cache the noise pattern for performance
  // (avoiding regenerating the noise each build)
  static const int _noiseResolution = 128;
  static List<List<double>>? _noiseCache;
  late final List<List<double>> _noisePattern;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller if animation is enabled
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    
    if (widget.animate) {
      _animationController.repeat();
    }
    
    // Generate or use cached noise pattern
    _noisePattern = _getNoisePattern();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(MicroGrainTexture oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Handle animation state change
    if (widget.animate != oldWidget.animate) {
      if (widget.animate) {
        _animationController.repeat();
      } else {
        _animationController.stop();
      }
    }
  }
  
  /// Generates or retrieves a cached noise pattern
  List<List<double>> _getNoisePattern() {
    // Use cached pattern if available
    if (_noiseCache != null) {
      return _noiseCache!;
    }
    
    // Generate new noise pattern
    final random = Random(42); // Fixed seed for consistent texture
    final pattern = List.generate(
      _noiseResolution,
      (_) => List.generate(
        _noiseResolution, 
        (_) => random.nextDouble(),
      ),
    );
    
    // Cache for reuse
    _noiseCache = pattern;
    return pattern;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // The base child widget
        widget.child,
        
        // The grain overlay
        Positioned.fill(
          child: widget.animate
              ? AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, _) => _buildGrainOverlay(),
                )
              : _buildGrainOverlay(),
        ),
      ],
    );
  }
  
  Widget _buildGrainOverlay() {
    // For animation, use the controller value to offset the noise
    final double offsetX = widget.animate ? _animationController.value * 20 : 0;
    final double offsetY = widget.animate ? _animationController.value * 10 : 0;
    
    return Opacity(
      opacity: widget.opacity,
      child: CustomPaint(
        painter: _GrainPainter(
          noisePattern: _noisePattern,
          grainColor: widget.grainColor,
          blendMode: widget.blendMode,
          offsetX: offsetX,
          offsetY: offsetY,
        ),
      ),
    );
  }
}

/// Custom painter that draws the grain texture
class _GrainPainter extends CustomPainter {
  final List<List<double>> noisePattern;
  final Color grainColor;
  final BlendMode blendMode;
  final double offsetX;
  final double offsetY;
  
  _GrainPainter({
    required this.noisePattern,
    required this.grainColor,
    required this.blendMode,
    this.offsetX = 0,
    this.offsetY = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final int resolution = noisePattern.length;
    final paint = Paint()
      ..color = grainColor
      ..blendMode = blendMode;
    
    // Calculate the size of each noise pixel
    final double pixelWidth = size.width / 64;
    final double pixelHeight = size.height / 64;
    
    // Draw noise pixels
    for (int y = 0; y < 64; y++) {
      for (int x = 0; x < 64; x++) {
        // Get noise value with wrapping for animation
        final int xIndex = ((x + offsetX.toInt()) % resolution).toInt();
        final int yIndex = ((y + offsetY.toInt()) % resolution).toInt();
        final double noiseValue = noisePattern[yIndex][xIndex];
        
        // Apply noise value to opacity
        paint.color = grainColor.withOpacity(noiseValue * 0.15);
        
        // Draw the noise pixel
        canvas.drawRect(
          Rect.fromLTWH(
            x * pixelWidth, 
            y * pixelHeight, 
            pixelWidth, 
            pixelHeight,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_GrainPainter oldPainter) => 
      oldPainter.offsetX != offsetX || 
      oldPainter.offsetY != offsetY ||
      oldPainter.grainColor != grainColor || 
      oldPainter.blendMode != blendMode;
} 