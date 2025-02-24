import 'package:flutter/material.dart';

class FlatButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double borderWidth;
  final Color borderColor;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final String fontFamily;
  final List<Color> animatedBorderColor;
  final Duration animationDuration;
  final double borderRadius;

  const FlatButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.width = 200,
    this.height = 56,
    this.borderWidth = 0.8,
    this.borderColor = Colors.transparent,
    this.backgroundColor = Colors.transparent,
    this.textColor = Colors.white,
    this.fontSize = 18,
    this.fontWeight = FontWeight.w600,
    this.fontFamily = 'Outfit',
    this.animatedBorderColor = const [],
    this.animationDuration = const Duration(seconds: 2),
    this.borderRadius = 14,
  }) : super(key: key);

  @override
  _FlatButtonState createState() => _FlatButtonState();
}

class _FlatButtonState extends State<FlatButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            side: BorderSide(
              color: widget.borderColor,
              width: widget.borderWidth,
            ),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        ),
        child: Text(
          widget.text,
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            color: widget.textColor,
            fontFamily: widget.fontFamily,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
} 