import 'package:flutter/material.dart';
import 'dart:math' as math;

class HexagonAvatar extends StatelessWidget {
  final double size;
  final ImageProvider? image;
  final VoidCallback? onTap;
  final bool isEditing;
  
  const HexagonAvatar({
    super.key,
    this.size = 80,
    this.image,
    this.onTap,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            CustomPaint(
              size: Size(size, size),
              painter: _HexagonPainter(
                borderColor: Colors.white.withOpacity(0.1),
                fillColor: Colors.white.withOpacity(0.05),
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
      ),
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
    
    // Draw subtle gradient background
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        fillColor.withOpacity(0.2),
        fillColor.withOpacity(0.1),
      ],
    );
    
    final paint = Paint()
      ..shader = gradient.createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, paint);

    // Draw border
    paint
      ..shader = null
      ..style = PaintingStyle.stroke
      ..color = borderColor
      ..strokeWidth = 1.5;
    canvas.drawPath(path, paint);
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