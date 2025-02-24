import 'package:flutter/material.dart';

class HiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final bool isInteractive;
  final VoidCallback? onTap;
  final bool isHighlighted;

  const HiveCard({
    super.key,
    required this.child,
    this.padding,
    this.isInteractive = false,
    this.onTap,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isInteractive ? onTap : null,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isHighlighted 
              ? const Color(0xFFEEBA2A).withOpacity(0.3)
              : Colors.white.withOpacity(0.1),
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isHighlighted 
                ? const Color(0xFFEEBA2A).withOpacity(0.1)
                : Colors.white.withOpacity(0.05),
              Colors.black.withOpacity(0.5),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                ? const Color(0xFFEEBA2A).withOpacity(0.1)
                : Colors.black.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: child,
      ),
    );
  }
} 