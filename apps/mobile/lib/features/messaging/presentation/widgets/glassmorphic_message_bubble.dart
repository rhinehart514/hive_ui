import 'package:flutter/material.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A message bubble with glassmorphic effect
class GlassmorphicMessageBubble extends StatelessWidget {
  /// The child widget to display inside the bubble
  final Widget child;
  
  /// Whether the message is from the current user
  final bool isFromCurrentUser;
  
  /// Background color for the bubble (will be applied with opacity)
  final Color? backgroundColor;
  
  /// Border radius
  final BorderRadius? borderRadius;
  
  /// Border width
  final double borderWidth;
  
  /// Blur value for the glassmorphic effect
  final double blur;
  
  /// Opacity for the glassmorphic effect
  final double opacity;
  
  /// Border gradient colors
  final List<Color>? borderGradient;
  
  /// Padding inside the bubble
  final EdgeInsets padding;
  
  const GlassmorphicMessageBubble({
    Key? key,
    required this.child,
    required this.isFromCurrentUser,
    this.backgroundColor,
    this.borderRadius,
    this.borderWidth = 0.5,
    this.blur = 10,
    this.opacity = 0.2,
    this.borderGradient,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Default colors based on sender
    final defaultBg = isFromCurrentUser 
        ? AppColors.gold.withOpacity(0.1)
        : Colors.grey.shade800.withOpacity(0.2);
    
    // Default border radius based on sender
    final defaultBorderRadius = isFromCurrentUser
        ? const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          );
    
    // Default border gradient
    final defaultBorderGradient = isFromCurrentUser
        ? [
            AppColors.gold.withOpacity(0.5),
            AppColors.gold.withOpacity(0.2),
          ]
        : [
            Colors.white.withOpacity(0.2),
            Colors.white.withOpacity(0.05),
          ];
    
    // Get the border radius to use
    final finalBorderRadius = borderRadius ?? defaultBorderRadius;

    return GlassmorphicContainer(
      width: double.infinity,
      height: double.infinity, // Changed from null
      borderRadius: finalBorderRadius.topLeft.x,
      blur: blur,
      alignment: Alignment.center,
      border: borderWidth,
      linearGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          backgroundColor ?? defaultBg,
          backgroundColor ?? defaultBg,
        ],
      ),
      borderGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: borderGradient ?? defaultBorderGradient,
      ),
      margin: EdgeInsets.zero,
      padding: padding,
      child: child,
    );
  }
}

/// A shimmer effect for message loading states
class MessageShimmer extends StatelessWidget {
  /// Whether the shimmer is for a sent message
  final bool isSent;
  
  const MessageShimmer({
    Key? key,
    this.isSent = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: GlassmorphicMessageBubble(
        isFromCurrentUser: isSent,
        opacity: 0.1,
        child: Container(
          width: 200,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey.shade800.withOpacity(0.2),
                Colors.grey.shade700.withOpacity(0.3),
                Colors.grey.shade800.withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
} 
 
 