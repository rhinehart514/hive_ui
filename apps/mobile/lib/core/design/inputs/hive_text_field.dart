import 'package:flutter/material.dart';
import 'dart:math' as math;

/// HIVE Tech Slate Text Field - Ultimate Sleek Surface Treatment
/// Smooth, tech, sleek aesthetic with auto-expanding height and refined animations
class HiveTechSlateField extends StatefulWidget {
  final String? label;
  final String? hint;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;
  final bool isError;
  final String? errorText;
  final int? maxLines;
  final TextInputType? keyboardType;
  final double? minHeight;
  final bool isPassword;
  final bool isDisabled;

  const HiveTechSlateField({
    super.key,
    this.label,
    this.hint,
    this.onChanged,
    this.controller,
    this.isError = false,
    this.errorText,
    this.maxLines,
    this.keyboardType,
    this.minHeight,
    this.isPassword = false,
    this.isDisabled = false,
  });

  @override
  State<HiveTechSlateField> createState() => _HiveTechSlateFieldState();
}

class _HiveTechSlateFieldState extends State<HiveTechSlateField>
    with TickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _focusController;
  late AnimationController _slidingBorderController;
  
  bool _isFocused = false;
  double _textHeight = 56;
  final double _borderProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _textHeight = widget.minHeight ?? 56;
    
    // Focus animation controller
    _focusController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Sliding border animation controller  
    _slidingBorderController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      
      if (_isFocused) {
        _focusController.forward();
        _slidingBorderController.forward();
      } else {
        _focusController.reverse();
        _slidingBorderController.reverse();
      }
    });

    _controller.addListener(_updateHeight);
  }

  void _updateHeight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: _controller.text.isEmpty ? widget.hint ?? '' : _controller.text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          textDirection: TextDirection.ltr,
          maxLines: widget.maxLines,
        );
        textPainter.layout(maxWidth: 300);
        
        final newHeight = math.max(
          widget.minHeight ?? 56,
          textPainter.height + 32, // Padding for top/bottom
        );
        
        if ((newHeight - _textHeight).abs() > 2) {
          setState(() {
            _textHeight = newHeight;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_updateHeight);
    if (widget.controller == null) {
      _controller.dispose();
    }
    _focusNode.dispose();
    _focusController.dispose();
    _slidingBorderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              color: _isFocused 
                ? const Color(0xFFFFD700)
                : Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Tech Slate Field with Sliding Border Focus
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          height: _textHeight,
          child: CustomPaint(
            painter: _SlidingBorderPainter(
              progress: _slidingBorderController.value,
              isActive: _isFocused,
              hasError: widget.isError,
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: widget.isDisabled 
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFF0F0F0F), // Ultimate dark tech slate
                border: Border.all(
                  color: widget.isError
                    ? const Color(0xFFFF3B30)
                    : (_isFocused 
                      ? Colors.transparent // Border handled by custom painter
                      : Colors.white.withOpacity(0.1)),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.6),
                    blurRadius: _isFocused ? 12 : 4,
                    offset: Offset(0, _isFocused ? 2 : 1),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: widget.onChanged,
                maxLines: widget.maxLines,
                keyboardType: widget.keyboardType,
                enabled: !widget.isDisabled,
                obscureText: widget.isPassword,
                style: TextStyle(
                  color: widget.isDisabled 
                    ? Colors.white.withOpacity(0.5)
                    : Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  hintStyle: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
        
        if (widget.isError && widget.errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.errorText!,
            style: const TextStyle(
              color: Color(0xFFFF3B30),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}

/// Custom painter for the sliding border focus effect
class _SlidingBorderPainter extends CustomPainter {
  final double progress;
  final bool isActive;
  final bool hasError;

  _SlidingBorderPainter({
    required this.progress,
    required this.isActive,
    required this.hasError,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || hasError) return;

    final paint = Paint()
      ..color = const Color(0xFFFFD700) // HIVE gold accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    final path = Path()..addRRect(rect);
    final pathMetrics = path.computeMetrics();
    
    for (final pathMetric in pathMetrics) {
      final extractPath = pathMetric.extractPath(
        0.0,
        pathMetric.length * progress,
      );
      canvas.drawPath(extractPath, paint);
    }
  }

  @override
  bool shouldRepaint(_SlidingBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.isActive != isActive ||
           oldDelegate.hasError != hasError;
  }
} 