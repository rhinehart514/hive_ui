import 'dart:math' as math;
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';

/// A widget that adds a micro-grain texture overlay to its child
/// as specified in the HIVE brand aesthetic guidelines.
class TextureOverlay extends StatelessWidget {
  /// The widget below this widget in the tree.
  final Widget child;
  
  /// Opacity of the grain texture (recommended: 0.02-0.05)
  final double opacity;
  
  /// Whether to animate the grain for "living surfaces"
  final bool animate;
  
  /// Color of the grain texture (default: gold)
  final Color color;
  
  /// Creates a micro-grain texture overlay.
  /// 
  /// The [opacity] parameter should be between 0.02 and 0.05 as per
  /// HIVE brand aesthetic guidelines.
  /// 
  /// Set [animate] to true for "Cold/Empty States" as specified in the guidelines
  /// where empty cards should subtly animate with 1% grain shift.
  const TextureOverlay({
    super.key,
    required this.child,
    this.opacity = 0.03,
    this.animate = false,
    this.color = const Color(0xFFFFD700), // Default to gold color
  }) : assert(opacity >= 0.0 && opacity <= 0.1, 'Opacity should be between 0.0 and 0.1');

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: animate 
              ? _AnimatedNoiseTexture(opacity: opacity, color: color)
              : _NoiseTexture(opacity: opacity, color: color),
        ),
      ],
    );
  }
}

/// Static noise texture overlay
class _NoiseTexture extends StatelessWidget {
  final double opacity;
  final Color color;

  const _NoiseTexture({required this.opacity, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NoisePainter(opacity: opacity, color: color),
      size: Size.infinite,
    );
  }
}

/// Animated noise texture overlay with subtle movement
class _AnimatedNoiseTexture extends StatefulWidget {
  final double opacity;
  final Color color;

  const _AnimatedNoiseTexture({required this.opacity, required this.color});

  @override
  State<_AnimatedNoiseTexture> createState() => _AnimatedNoiseTextureState();
}

class _AnimatedNoiseTextureState extends State<_AnimatedNoiseTexture> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
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
        return CustomPaint(
          painter: _NoisePainter(
            opacity: widget.opacity,
            color: widget.color,
            seed: (_controller.value * 100).toInt(),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Custom painter that renders a noise texture
class _NoisePainter extends CustomPainter {
  final double opacity;
  final Color color;
  final int seed;
  final int pixelDensity;
  
  // Stored random pixels for performance
  late List<bool> _noiseMap;
  
  _NoisePainter({
    required this.opacity, 
    required this.color,
    this.seed = 42,
    this.pixelDensity = 100, // Default pixel density for texture
  }) {
    final random = math.Random(seed);
    // Pre-generate noise map
    _noiseMap = List.generate(
      pixelDensity * pixelDensity, 
      (_) => random.nextDouble() > 0.85, // ~15% of pixels are active
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    
    final pixelSize = size.width / pixelDensity;
    
    // Draw only active pixels from the pre-generated map
    for (int y = 0; y < pixelDensity; y++) {
      for (int x = 0; x < pixelDensity; x++) {
        final index = y * pixelDensity + x;
        if (index < _noiseMap.length && _noiseMap[index]) {
          final pixelX = x * pixelSize;
          final pixelY = y * pixelSize;
          canvas.drawPoints(
            PointMode.points,
            [Offset(pixelX, pixelY)],
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_NoisePainter oldDelegate) => 
    opacity != oldDelegate.opacity || seed != oldDelegate.seed;
} 