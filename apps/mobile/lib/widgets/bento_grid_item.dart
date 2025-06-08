import 'package:flutter/material.dart';

class BentoGridItem extends StatelessWidget {
  final Widget child;
  final double? height;
  final int flex;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final bool isActive;

  const BentoGridItem({
    super.key,
    required this.child,
    this.height,
    this.flex = 1,
    this.backgroundColor,
    this.onTap,
    this.padding,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: height,
          padding: padding ?? const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.white.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
