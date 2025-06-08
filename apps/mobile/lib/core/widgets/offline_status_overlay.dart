import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/widgets/offline_status_indicator.dart';

/// An overlay that displays the offline status and pending operations
/// This should be added to the widget tree at the application level
class OfflineStatusOverlay extends ConsumerWidget {
  /// The child widget
  final Widget child;
  
  /// Whether to show the overlay at the bottom or top
  final bool showAtBottom;
  
  /// Padding from the edge
  final double edgePadding;
  
  /// Constructor
  const OfflineStatusOverlay({
    Key? key,
    required this.child,
    this.showAtBottom = true,
    this.edgePadding = 16.0,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      alignment: Alignment.center,
      children: [
        child,
        Positioned(
          bottom: showAtBottom ? edgePadding : null,
          top: showAtBottom ? null : edgePadding,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: OfflineStatusIndicator(
                isOverlay: true,
                onTap: () => showOfflineActionsDialog(context),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Provider for whether the offline overlay should be shown
final showOfflineOverlayProvider = StateProvider<bool>((ref) => true);

/// A wrapper widget that conditionally shows the offline overlay
class ConditionalOfflineStatusOverlay extends ConsumerWidget {
  /// The child widget
  final Widget child;
  
  /// Constructor
  const ConditionalOfflineStatusOverlay({
    Key? key,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showOverlay = ref.watch(showOfflineOverlayProvider);
    
    if (showOverlay) {
      return OfflineStatusOverlay(child: child);
    } else {
      return child;
    }
  }
} 