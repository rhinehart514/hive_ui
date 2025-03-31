import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/messaging/application/providers/messaging_providers.dart';
import 'package:hive_ui/theme/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

/// A widget that displays a user's online status or last seen time
class OnlineStatusIndicator extends ConsumerWidget {
  final String userId;
  final TextStyle? textStyle;
  final bool showOfflineStatus;
  final bool compactMode;

  const OnlineStatusIndicator({
    Key? key,
    required this.userId,
    this.textStyle,
    this.showOfflineStatus = true,
    this.compactMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the online status
    final onlineStatusAsync = ref.watch(userOnlineStatusProvider(userId));
    
    return onlineStatusAsync.when(
      data: (isOnline) {
        if (isOnline) {
          return _buildOnlineStatus();
        } else if (showOfflineStatus) {
          return _buildOfflineStatus(ref);
        } else {
          return const SizedBox.shrink();
        }
      },
      loading: () => const SizedBox(
        width: 8,
        height: 8,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildOnlineStatus() {
    final baseStyle = textStyle ?? 
        const TextStyle(fontSize: 12, color: Colors.white70);
    
    if (compactMode) {
      return Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Colors.green,
          shape: BoxShape.circle,
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Online',
          style: baseStyle.copyWith(color: Colors.green),
        ),
      ],
    );
  }

  Widget _buildOfflineStatus(WidgetRef ref) {
    // Get the last active timestamp
    final lastActiveAsync = ref.watch(userLastActiveProvider(userId));
    
    return lastActiveAsync.when(
      data: (lastActive) {
        if (lastActive == null) {
          return const SizedBox.shrink();
        }

        final baseStyle = textStyle ?? 
            const TextStyle(fontSize: 12, color: Colors.white70);
        
        if (compactMode) {
          return Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          );
        }
        
        return Text(
          'Last seen ${timeago.format(lastActive)}',
          style: baseStyle,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
} 