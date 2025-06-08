/// HIVE Card System - Official Component
/// 
/// Extracted from design system testing with locked-in user preferences:
/// - Surface: Sophisticated depth + minimalist flat pressed
/// - Texture: 2% grain overlay
/// - Interactive: Spring bounce animation
/// - Physics: Ease curve timing
/// - Hierarchy: Standard spacing
/// - Glass: Frosted glass treatment
/// - Responsive: Adaptive grid layouts

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool isPressed;
  final HiveCardVariant variant;

  const HiveCard({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.isPressed = false,
    this.variant = HiveCardVariant.sophisticatedDepth,
  });

  /// Primary card with sophisticated depth and premium shadows
  const HiveCard.sophisticatedDepth({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.isPressed = false,
  }) : variant = HiveCardVariant.sophisticatedDepth;

  /// Minimalist flat surface for pressed states
  const HiveCard.minimalistFlat({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.isPressed = false,
  }) : variant = HiveCardVariant.minimalistFlat;

  /// Frosted glass treatment with backdrop blur
  const HiveCard.frostedGlass({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
    this.isPressed = false,
  }) : variant = HiveCardVariant.frostedGlass;

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isLocalPressed = isPressed;

        return GestureDetector(
          onTapDown: onTap != null ? (_) {
            setState(() => isLocalPressed = true);
            HapticFeedback.lightImpact();
          } : null,
          onTapUp: onTap != null ? (_) {
            setState(() => isLocalPressed = false);
            onTap?.call();
          } : null,
          onTapCancel: onTap != null ? () {
            setState(() => isLocalPressed = false);
          } : null,
          child: AnimatedScale(
            scale: isLocalPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              width: width,
              height: height,
              decoration: _buildDecoration(isLocalPressed),
              child: _buildCardContent(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardContent() {
    Widget content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    // Add 2% grain texture overlay
    return Stack(
      children: [
        content,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.02),
                  Colors.transparent,
                  Colors.white.withOpacity(0.02),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildDecoration(bool isPressed) {
    switch (variant) {
      case HiveCardVariant.sophisticatedDepth:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1E1E),
              Color(0xFF2A2A2A),
            ],
          ),
          boxShadow: [
            // Primary depth shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: isPressed ? 4 : 12,
              offset: Offset(0, isPressed ? 2 : 6),
              spreadRadius: isPressed ? 0 : 1,
            ),
            // Secondary ambient shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: isPressed ? 8 : 24,
              offset: Offset(0, isPressed ? 4 : 12),
              spreadRadius: isPressed ? 1 : 2,
            ),
            // Inner highlight (achieved through gradient)
          ],
        );

      case HiveCardVariant.minimalistFlat:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1A1A1A),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        );

      case HiveCardVariant.frostedGlass:
        return BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF161616).withOpacity(0.7),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
          ],
        );
    }
  }
}

/// Card variant for frosted glass with backdrop filter
class HiveCardWithBackdrop extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;

  const HiveCardWithBackdrop({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isPressed = false;

        return GestureDetector(
          onTapDown: onTap != null ? (_) {
            setState(() => isPressed = true);
            HapticFeedback.lightImpact();
          } : null,
          onTapUp: onTap != null ? (_) {
            setState(() => isPressed = false);
            onTap?.call();
          } : null,
          onTapCancel: onTap != null ? () {
            setState(() => isPressed = false);
          } : null,
          child: AnimatedScale(
            scale: isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            child: Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161616).withOpacity(0.7),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.08),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      gradient: const RadialGradient(
                        center: Alignment.topLeft,
                        radius: 1.5,
                        colors: [
                          Color.fromRGBO(255, 255, 255, 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: padding ?? const EdgeInsets.all(16),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Responsive card grid system
class HiveCardGrid extends StatelessWidget {
  final List<Widget> cards;
  final double? spacing;
  final EdgeInsetsGeometry? padding;

  const HiveCardGrid({
    super.key,
    required this.cards,
    this.spacing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        
        // Responsive columns based on screen width
        int columns;
        if (screenWidth <= 400) {
          columns = 1; // Mobile single
        } else if (screenWidth <= 767) {
          columns = 2; // Mobile dual
        } else if (screenWidth <= 1023) {
          columns = 3; // Tablet triple
        } else {
          columns = 4; // Desktop quad
        }

        return Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: columns,
            crossAxisSpacing: spacing ?? 16,
            mainAxisSpacing: spacing ?? 16,
            childAspectRatio: 1.2,
            children: cards,
          ),
        );
      },
    );
  }
}

/// Card content hierarchy helper
class HiveCardContent extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final HiveCardContentHierarchy hierarchy;

  const HiveCardContent({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.hierarchy = HiveCardContentHierarchy.standard,
  });

  @override
  Widget build(BuildContext context) {
    final spacing = _getSpacing();
    final titleStyle = _getTitleStyle();
    final subtitleStyle = _getSubtitleStyle();

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          SizedBox(width: spacing),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: titleStyle),
              if (subtitle != null) ...[
                SizedBox(height: spacing / 2),
                Text(subtitle!, style: subtitleStyle),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          SizedBox(width: spacing),
          trailing!,
        ],
      ],
    );
  }

  double _getSpacing() {
    switch (hierarchy) {
      case HiveCardContentHierarchy.compact:
        return 8.0;
      case HiveCardContentHierarchy.standard:
        return 16.0;
      case HiveCardContentHierarchy.comfortable:
        return 24.0;
    }
  }

  TextStyle _getTitleStyle() {
    return const TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
  }

  TextStyle _getSubtitleStyle() {
    return TextStyle(
      color: Colors.white.withOpacity(0.7),
      fontSize: 14,
      fontWeight: FontWeight.w400,
    );
  }
}

enum HiveCardVariant {
  sophisticatedDepth,
  minimalistFlat,
  frostedGlass,
}

enum HiveCardContentHierarchy {
  compact,
  standard,
  comfortable,
} 