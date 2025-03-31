import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

/// Style options for HiveCard
enum HiveCardStyle {
  /// Standard style with dark background and subtle border
  standard,

  /// Elevated style with shadow and more pronounced border
  elevated,

  /// Glassmorphic style with blur effect
  glass,

  /// Gold accent style for premium or important content
  accent,

  /// Minimal style with less padding and subtle border
  minimal,
}

/// A standardized card component for Hive UI
class HiveCard extends StatelessWidget {
  /// Card content
  final Widget child;

  /// Card style
  final HiveCardStyle style;

  /// Optional padding override
  final EdgeInsetsGeometry? padding;

  /// Optional margin override
  final EdgeInsetsGeometry? margin;

  /// Whether to provide haptic feedback on tap
  final bool hapticFeedback;

  /// Optional tap callback
  final VoidCallback? onTap;

  /// Optional long press callback
  final VoidCallback? onLongPress;

  /// Optional corner radius override
  final double? borderRadius;

  /// Optional border color override
  final Color? borderColor;

  /// Optional background color override
  final Color? backgroundColor;

  /// Optional elevation override
  final double? elevation;

  /// Optional clip behavior
  final Clip clipBehavior;

  /// Standard constructor
  const HiveCard({
    super.key,
    required this.child,
    this.style = HiveCardStyle.standard,
    this.padding,
    this.margin,
    this.hapticFeedback = true,
    this.onTap,
    this.onLongPress,
    this.borderRadius,
    this.borderColor,
    this.backgroundColor,
    this.elevation,
    this.clipBehavior = Clip.antiAlias,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadiusValue = borderRadius ?? _getBorderRadius();
    final cardMargin = margin ?? _getMargin();
    final cardPadding = padding ?? _getPadding();
    final cardBorderColor = borderColor ?? _getBorderColor(context);
    final cardBackgroundColor = backgroundColor ?? _getBackgroundColor(context);
    final cardElevation = elevation ?? _getElevation();

    Widget card = Container(
      decoration: BoxDecoration(
        color: cardBackgroundColor,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        border: Border.all(
          color: cardBorderColor,
          width: style == HiveCardStyle.accent ? 1.5 : 0.5,
        ),
        boxShadow: cardElevation > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: cardElevation * 2,
                  spreadRadius: cardElevation / 2,
                  offset: Offset(0, cardElevation / 2),
                ),
              ]
            : null,
      ),
      margin: cardMargin,
      clipBehavior: clipBehavior,
      child: Padding(
        padding: cardPadding,
        child: child,
      ),
    );

    if (style == HiveCardStyle.glass) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadiusValue),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: card,
        ),
      );
    }

    if (onTap != null || onLongPress != null) {
      card = InkWell(
        onTap: onTap != null
            ? () {
                if (hapticFeedback) {
                  HapticFeedback.lightImpact();
                }
                onTap!();
              }
            : null,
        onLongPress: onLongPress != null
            ? () {
                if (hapticFeedback) {
                  HapticFeedback.mediumImpact();
                }
                onLongPress!();
              }
            : null,
        borderRadius: BorderRadius.circular(borderRadiusValue),
        splashColor: AppColors.gold.withOpacity(0.1),
        highlightColor: AppColors.gold.withOpacity(0.05),
        child: card,
      );
    }

    return card;
  }

  /// Get the appropriate border radius for the current style
  double _getBorderRadius() {
    switch (style) {
      case HiveCardStyle.standard:
      case HiveCardStyle.elevated:
      case HiveCardStyle.glass:
        return 20.0;
      case HiveCardStyle.accent:
        return 24.0;
      case HiveCardStyle.minimal:
        return 12.0;
    }
  }

  /// Get the appropriate margin for the current style
  EdgeInsetsGeometry _getMargin() {
    switch (style) {
      case HiveCardStyle.standard:
      case HiveCardStyle.elevated:
      case HiveCardStyle.glass:
      case HiveCardStyle.accent:
        return const EdgeInsets.all(8.0);
      case HiveCardStyle.minimal:
        return const EdgeInsets.all(4.0);
    }
  }

  /// Get the appropriate padding for the current style
  EdgeInsetsGeometry _getPadding() {
    switch (style) {
      case HiveCardStyle.standard:
      case HiveCardStyle.glass:
        return const EdgeInsets.all(16.0);
      case HiveCardStyle.elevated:
      case HiveCardStyle.accent:
        return const EdgeInsets.all(20.0);
      case HiveCardStyle.minimal:
        return const EdgeInsets.all(12.0);
    }
  }

  /// Get the appropriate border color for the current style
  Color _getBorderColor(BuildContext context) {
    switch (style) {
      case HiveCardStyle.standard:
      case HiveCardStyle.elevated:
      case HiveCardStyle.glass:
        return Theme.of(context).dividerColor.withOpacity(0.3);
      case HiveCardStyle.accent:
        return AppColors.gold;
      case HiveCardStyle.minimal:
        return Theme.of(context).dividerColor.withOpacity(0.15);
    }
  }

  /// Get the appropriate background color for the current style
  Color _getBackgroundColor(BuildContext context) {
    switch (style) {
      case HiveCardStyle.standard:
        return Theme.of(context).cardColor;
      case HiveCardStyle.elevated:
        return Theme.of(context).cardColor.withOpacity(0.9);
      case HiveCardStyle.glass:
        return Theme.of(context).cardColor.withOpacity(0.7);
      case HiveCardStyle.accent:
        return Colors.black;
      case HiveCardStyle.minimal:
        return Theme.of(context).cardColor;
    }
  }

  /// Get the appropriate elevation for the current style
  double _getElevation() {
    switch (style) {
      case HiveCardStyle.standard:
        return 0.0;
      case HiveCardStyle.elevated:
        return 4.0;
      case HiveCardStyle.glass:
        return 0.0;
      case HiveCardStyle.accent:
        return 6.0;
      case HiveCardStyle.minimal:
        return 0.0;
    }
  }
}

/// Factory methods for creating HiveCards with specific styles
extension HiveCardFactories on HiveCard {
  /// Create a standard HiveCard
  static HiveCard standard({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool hapticFeedback = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return HiveCard(
      style: HiveCardStyle.standard,
      padding: padding,
      margin: margin,
      hapticFeedback: hapticFeedback,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Create an elevated HiveCard
  static HiveCard elevated({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool hapticFeedback = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    double? elevation,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return HiveCard(
      style: HiveCardStyle.elevated,
      padding: padding,
      margin: margin,
      hapticFeedback: hapticFeedback,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      elevation: elevation,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Create a glass-style HiveCard
  static HiveCard glass({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool hapticFeedback = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return HiveCard(
      style: HiveCardStyle.glass,
      padding: padding,
      margin: margin,
      hapticFeedback: hapticFeedback,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Create an accent HiveCard
  static HiveCard accent({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool hapticFeedback = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    double? elevation,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return HiveCard(
      style: HiveCardStyle.accent,
      padding: padding,
      margin: margin,
      hapticFeedback: hapticFeedback,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      elevation: elevation,
      clipBehavior: clipBehavior,
      child: child,
    );
  }

  /// Create a minimal HiveCard
  static HiveCard minimal({
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    bool hapticFeedback = true,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    double? borderRadius,
    Color? borderColor,
    Color? backgroundColor,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    return HiveCard(
      style: HiveCardStyle.minimal,
      padding: padding,
      margin: margin,
      hapticFeedback: hapticFeedback,
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: borderRadius,
      borderColor: borderColor,
      backgroundColor: backgroundColor,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}
