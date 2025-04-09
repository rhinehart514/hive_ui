import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A small badge that indicates the pending status of an item
class PendingActionBadge extends StatelessWidget {
  /// Whether the action is pending
  final bool isPending;
  
  /// Size of the badge
  final double size;
  
  /// Color of the badge
  final Color? color;
  
  /// Constructor
  const PendingActionBadge({
    Key? key,
    required this.isPending,
    this.size = 8.0,
    this.color,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isPending) {
      return const SizedBox.shrink();
    }
    
    final badgeColor = color ?? Theme.of(context).colorScheme.secondary;
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: badgeColor,
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Styles for the offline status text
enum OfflineStatusTextStyle {
  /// Small subtle style
  subtle,
  
  /// More prominent style
  prominent,
  
  /// Large attention-grabbing style
  attention,
}

/// A text widget that shows the current pending status
class PendingActionText extends ConsumerWidget {
  /// Whether the action is pending
  final bool isPending;
  
  /// The style to use for the text
  final OfflineStatusTextStyle style;
  
  /// Custom text to show when pending
  final String? pendingText;
  
  /// Custom text to show when synced
  final String? syncedText;
  
  /// Whether to show the synced text
  final bool showSyncedText;
  
  /// Constructor
  const PendingActionText({
    Key? key,
    required this.isPending,
    this.style = OfflineStatusTextStyle.subtle,
    this.pendingText,
    this.syncedText,
    this.showSyncedText = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    // If not pending and we don't want to show synced text, show nothing
    if (!isPending && !showSyncedText) {
      return const SizedBox.shrink();
    }
    
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    
    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result != ConnectivityResult.wifi && 
                        result != ConnectivityResult.mobile && 
                        result != ConnectivityResult.ethernet,
      orElse: () => true,
    );
    
    final String text;
    final Color color;
    
    if (isPending) {
      text = pendingText ?? (isOffline ? 'Waiting for connection' : 'Syncing...');
      color = isOffline ? 
          theme.colorScheme.error : 
          theme.colorScheme.secondary;
    } else {
      text = syncedText ?? 'Synced';
      color = Colors.green;
    }
    
    // Apply the correct style
    TextStyle textStyle;
    switch (style) {
      case OfflineStatusTextStyle.subtle:
        textStyle = theme.textTheme.bodySmall!.copyWith(
          color: color,
          fontSize: 10,
        );
        break;
      case OfflineStatusTextStyle.prominent:
        textStyle = theme.textTheme.bodyMedium!.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        );
        break;
      case OfflineStatusTextStyle.attention:
        textStyle = theme.textTheme.bodyLarge!.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        );
        break;
    }
    
    return Text(
      text,
      style: textStyle,
    );
  }
}

/// A widget that shows a shimmer effect for pending items
class PendingActionShimmer extends StatelessWidget {
  /// Whether the action is pending
  final bool isPending;
  
  /// The child widget
  final Widget child;
  
  /// The color to use for the shimmer
  final Color? color;
  
  /// The opacity of the shimmer overlay
  final double opacity;
  
  /// Constructor
  const PendingActionShimmer({
    Key? key,
    required this.isPending,
    required this.child,
    this.color,
    this.opacity = 0.1,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (!isPending) {
      return child;
    }
    
    final shimmerColor = color ?? Colors.white;
    
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: _ShimmerEffect(
            color: shimmerColor,
            opacity: opacity,
          ),
        ),
      ],
    );
  }
}

/// A simple shimmer effect implementation
class _ShimmerEffect extends StatefulWidget {
  final Color color;
  final double opacity;
  
  const _ShimmerEffect({
    Key? key,
    required this.color,
    required this.opacity,
  }) : super(key: key);
  
  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.color.withOpacity(0),
                widget.color.withOpacity(widget.opacity),
                widget.color.withOpacity(0),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + _animation.value * 2.0, 0.0),
              end: Alignment(1.0 + _animation.value * 2.0, 0.0),
            ),
          ),
        );
      },
    );
  }
} 