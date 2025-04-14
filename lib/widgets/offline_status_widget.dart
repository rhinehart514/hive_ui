import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/providers/offline_mode_provider.dart';
import 'package:intl/intl.dart';

/// A widget that displays offline status information and controls
class OfflineStatusWidget extends ConsumerWidget {
  final bool showControls;
  
  const OfflineStatusWidget({super.key, this.showControls = true});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(offlineModeProvider);
    final hasSufficientData = ref.watch(hasSufficientOfflineDataProvider);
    final pendingChangesCount = ref.watch(pendingChangesCountProvider);
    final lastOnlineTime = ref.watch(lastOnlineTimeProvider);
    
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isOffline ? Icons.cloud_off : Icons.cloud_done,
                  color: isOffline ? Colors.red : Colors.green,
                ),
                const SizedBox(width: 8),
                Text(
                  isOffline ? 'Offline Mode' : 'Online Mode',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                if (showControls)
                  Switch(
                    value: isOffline,
                    onChanged: (value) {
                      ref.read(offlineModeProvider.notifier).setOfflineMode(value);
                    },
                  ),
              ],
            ),
            const Divider(),
            if (isOffline) ...[
              if (lastOnlineTime != null)
                Text(
                  'Last online: ${_formatDateTime(lastOnlineTime)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              const SizedBox(height: 8),
              Text(
                'Pending changes: $pendingChangesCount',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Offline data: ${hasSufficientData ? 'Sufficient' : 'Limited'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: hasSufficientData ? Colors.green : Colors.orange,
                ),
              ),
            ],
            if (showControls && !isOffline) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(offlineModeProvider.notifier).prefetchData();
                },
                child: const Text('Prefetch Data for Offline Use'),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return DateFormat('MMM d, h:mm a').format(dateTime);
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
} 