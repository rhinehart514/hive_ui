import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:hive_ui/models/user_profile.dart'; // Assuming UserProfile model path
import 'package:hive_ui/theme/app_colors.dart'; // Trying theme/app_colors.dart

class HexagonAvatar extends StatelessWidget {
  final double size;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final bool isEditing;
  final AccountTier? accountTier; // Add accountTier parameter

  const HexagonAvatar({
    super.key,
    this.size = 80,
    this.image,
    this.onTap,
    this.isEditing = false,
    this.accountTier, // Initialize accountTier
  });

  @override
  Widget build(BuildContext context) {
    final bool showBorder = accountTier == AccountTier.verifiedPlus;

    Widget avatarContent = SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none, // Allow border to potentially draw outside
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _HexagonPainter(
              // Make fill transparent if image exists, otherwise use subtle fill
              fillColor: image != null ? Colors.transparent : Colors.white.withOpacity(0.05),
              // Border becomes part of the outer container if showBorder is true
              borderColor: showBorder ? Colors.transparent : Colors.white.withOpacity(0.1),
            ),
          ),
          if (image != null)
            ClipPath(
              clipper: _HexagonClipper(),
              child: Image(
                image: image!,
                width: size,
                height: size,
                fit: BoxFit.cover,
              ),
            ),
          if (isEditing)
            Positioned.fill(
              child: ClipPath(
                clipper: _HexagonClipper(),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: Icon(
                      Icons.add_a_photo,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    // Wrap with border container if needed
    if (showBorder) {
      avatarContent = ClipPath(
        clipper: _HexagonClipper(), // Clip the border itself
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.gold, // Use gold from theme
              width: 2.0, // 2px width as per spec
            ),
            // Apply hexagon shape to container - ClipPath is likely better
            // shape: BoxShape.polygon, // Needs custom shape logic if BoxShape is used
          ),
          child: avatarContent, // Place original content inside bordered container
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: avatarContent, // Use potentially bordered content
    );
  }
}

class _HexagonPainter extends CustomPainter {
  final Color borderColor;
  final Color fillColor;

  _HexagonPainter({
    required this.borderColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _createHexagonPath(size);

    // Draw subtle gradient background or solid fill
    final Paint fillPaint;
    if (fillColor != Colors.transparent) {
       fillPaint = Paint()
        ..color = fillColor // Use solid fill for simplicity or keep gradient if preferred
        ..style = PaintingStyle.fill;
       // Optional: Keep gradient if desired
       // final gradient = LinearGradient(...);
       // fillPaint = Paint()..shader = gradient.createShader(...) ..style = PaintingStyle.fill;
       canvas.drawPath(path, fillPaint);
    }


    // Draw border only if borderColor is not transparent
    if (borderColor != Colors.transparent) {
      final borderPaint = Paint()
        ..style = PaintingStyle.stroke
        ..color = borderColor
        ..strokeWidth = 1.5; // Keep original border width for non-verified+
      canvas.drawPath(path, borderPaint);
    }
  }

  Path _createHexagonPath(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;
    final radius = math.min(width, height) / 2;
    final center = Offset(width / 2, height / 2);

    for (var i = 0; i < 6; i++) {
      final angle = (i * 60 + 30) * math.pi / 180;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_HexagonPainter oldDelegate) =>
      borderColor != oldDelegate.borderColor ||
      fillColor != oldDelegate.fillColor;
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return _HexagonPainter(
      borderColor: Colors.transparent,
      fillColor: Colors.transparent,
    )._createHexagonPath(size);
  }

  @override
  bool shouldReclip(_HexagonClipper oldClipper) => false;
}
