import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/presentation/providers/watchlist_provider.dart';
import 'package:hive_ui/features/spaces/presentation/widgets/glassmorphic_container.dart';
import 'package:hive_ui/core/theme/app_colors.dart';

/// Button to watch/unwatch a space
class WatchSpaceButton extends ConsumerWidget {
  /// Space ID
  final String spaceId;
  
  /// Custom icon size
  final double? iconSize;
  
  /// Custom icon color
  final Color? iconColor;
  
  /// Whether to show text label beside the icon
  final bool showLabel;
  
  /// Whether to show as a GlassMorphic container
  final bool useGlassMorphism;
  
  /// Callback when the watch status changes
  final Function(bool isWatching)? onWatchStatusChanged;
  
  /// Constructor
  const WatchSpaceButton({
    super.key,
    required this.spaceId,
    this.iconSize,
    this.iconColor,
    this.showLabel = false,
    this.useGlassMorphism = false,
    this.onWatchStatusChanged,
  });
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get the current watch status
    final isWatchingAsync = ref.watch(isWatchingSpaceProvider(spaceId));
    final watcherCountAsync = ref.watch(watcherCountProvider(spaceId));
    
    // Get the controller for actions
    final controller = ref.watch(watchlistControllerProvider.notifier);
    final controllerState = ref.watch(watchlistControllerProvider);
    
    // Handle the toggle action
    void toggleWatch() async {
      final result = await controller.toggleWatchStatus(spaceId);
      if (result && onWatchStatusChanged != null) {
        // Get the updated watch status
        final isWatching = await ref.read(isWatchingSpaceProvider(spaceId).future);
        onWatchStatusChanged!(isWatching);
      }
    }
    
    // Display a tooltip message for haptic feedback
    void showWatchTooltip(BuildContext context, bool isWatching) {
      final scaffold = ScaffoldMessenger.of(context);
      scaffold.clearSnackBars();
      scaffold.showSnackBar(
        SnackBar(
          content: Text(
            isWatching 
                ? "You're now watching this space" 
                : "Removed from your watchlist",
            textAlign: TextAlign.center,
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.8,
            left: 20,
            right: 20,
          ),
        ),
      );
    }

    // Build the actual button based on the watch status
    return GestureDetector(
      onLongPress: () {
        // Provide haptic feedback
        HapticFeedback.mediumImpact();
        toggleWatch();
        
        // Show tooltip for the action
        isWatchingAsync.whenData((isWatching) {
          showWatchTooltip(context, !isWatching); // Inverted because we're toggling
        });
      },
      child: isWatchingAsync.when(
        data: (isWatching) {
          final icon = isWatching
              ? Icons.visibility
              : Icons.visibility_outlined;
          
          final label = isWatching
              ? 'Watching'
              : 'Watch';
          
          // Count badge
          Widget? countBadge;
          if (isWatching) {
            countBadge = watcherCountAsync.when(
              data: (count) {
                return count > 0
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, 
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          count.toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              },
              loading: () => const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, __) => const SizedBox.shrink(),
            );
          }
          
          // Build the content
          Widget content = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize ?? 24,
                color: iconColor ?? (isWatching ? AppColors.accentGold : Colors.white70),
              ),
              if (showLabel)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isWatching ? AppColors.accentGold : Colors.white70,
                      fontWeight: isWatching ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              if (countBadge != null && showLabel)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: countBadge,
                ),
            ],
          );
          
          // Wrap in glassmorphic container if specified
          if (useGlassMorphism) {
            return GlassMorphicContainer(
              borderRadius: BorderRadius.circular(30),
              blur: 10,
              opacity: 0.2,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 8.0,
                ),
                child: content,
              ),
            );
          }
          
          return content;
        },
        loading: () => SizedBox(
          width: iconSize ?? 24,
          height: iconSize ?? 24,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
        error: (_, __) => Icon(
          Icons.error_outline,
          size: iconSize ?? 24,
          color: Colors.red,
        ),
      ),
    );
  }
}

/// A simple version of the watch space button optimized for space cards
class WatchSpaceIconButton extends WatchSpaceButton {
  /// Constructor
  const WatchSpaceIconButton({
    super.key,
    required super.spaceId,
    super.iconSize = 20,
    super.iconColor,
    super.onWatchStatusChanged,
  }) : super(
    showLabel: false,
    useGlassMorphism: false,
  );
}

/// Glassmorphic version of the watch space button with label
class GlassMorphicWatchSpaceButton extends WatchSpaceButton {
  /// Constructor
  const GlassMorphicWatchSpaceButton({
    super.key,
    required super.spaceId,
    super.iconSize = 18,
    super.iconColor,
    super.onWatchStatusChanged,
  }) : super(
    showLabel: true,
    useGlassMorphism: true,
  );
} 