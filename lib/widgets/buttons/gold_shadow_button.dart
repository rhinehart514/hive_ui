import 'package:flutter/material.dart';

class GoldShadowButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;

  const GoldShadowButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.width = 353,
  });

  @override
  State<GoldShadowButton> createState() => _GoldShadowButtonState();
}

class _GoldShadowButtonState extends State<GoldShadowButton> {
  double _scale = 1.0;
  final Duration _duration = const Duration(milliseconds: 100);

  void _onTapDown(TapDownDetails details) {
    setState(() => _scale = 0.95);
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _scale = 1.0);
    widget.onPressed();
  }

  void _onTapCancel() {
    setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedScale(
        scale: _scale,
        duration: _duration,
        child: Container(
          width: widget.width,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(238, 186, 42, 0.25),
                offset: Offset(0, 4),
                blurRadius: 4,
              ),
            ],
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
} 