import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Widget for displaying an unread message count badge
class UnreadCountBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  
  const UnreadCountBadge({
    Key? key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.gold,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _formatCount(count),
          style: TextStyle(
            color: textColor ?? Colors.black,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
  
  /// Formats the count for display, showing 99+ for large numbers
  String _formatCount(int count) {
    if (count > 99) return '99+';
    return count.toString();
  }
}

/// Widget that animates the unread count badge when it changes
class AnimatedUnreadCountBadge extends ConsumerWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;
  final double size;
  
  const AnimatedUnreadCountBadge({
    Key? key,
    required this.count,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: UnreadCountBadge(
        key: ValueKey<int>(count),
        count: count,
        backgroundColor: backgroundColor,
        textColor: textColor,
        size: size,
      ),
    );
  }
} 
 
 