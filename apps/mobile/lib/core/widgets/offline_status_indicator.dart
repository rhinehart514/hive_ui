import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/network/offline_action.dart';

/// A widget that displays the current offline status and pending actions
class OfflineStatusIndicator extends ConsumerWidget {
  /// Whether to show the indicator as an overlay or inline
  final bool isOverlay;
  
  /// Callback when the indicator is tapped
  final VoidCallback? onTap;
  
  /// Constructor
  const OfflineStatusIndicator({
    Key? key,
    this.isOverlay = false,
    this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    
    return connectivityStatus.when(
      data: (status) => _buildContent(context, status, pendingActions),
      loading: () => _buildContent(context, ConnectivityResult.none, pendingActions),
      error: (_, __) => _buildContent(context, ConnectivityResult.none, pendingActions),
    );
  }
  
  Widget _buildContent(BuildContext context, ConnectivityResult status, List<OfflineAction> pendingActions) {
    // If online and no pending actions, don't show anything
    if ((status == ConnectivityResult.wifi || 
         status == ConnectivityResult.mobile || 
         status == ConnectivityResult.ethernet) && 
         pendingActions.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final theme = Theme.of(context);
    final isOffline = status != ConnectivityResult.wifi && 
                      status != ConnectivityResult.mobile && 
                      status != ConnectivityResult.ethernet;
    
    // Determine colors based on status
    final backgroundColor = isOffline
        ? Colors.red.withOpacity(0.9)
        : Colors.orange.withOpacity(0.9);
    
    final message = isOffline
        ? 'You are offline'
        : 'Syncing ${pendingActions.length} item${pendingActions.length == 1 ? '' : 's'}';
    
    final icon = isOffline
        ? Icons.wifi_off_rounded
        : Icons.sync_rounded;
    
    // Build the indicator
    final indicator = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    
    // Always return the GestureDetector directly regardless of isOverlay
    // This fixes the "Incorrect use of ParentDataWidget" error
    // The parent widget (OfflineStatusOverlay) will handle positioning
    return GestureDetector(
      onTap: onTap,
      child: indicator,
    );
  }
}

/// A widget that displays detailed information about pending offline actions
class OfflineActionsList extends ConsumerWidget {
  const OfflineActionsList({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actionsAsync = ref.watch(offlineActionsProvider);
    
    return actionsAsync.when(
      data: (actions) {
        if (actions.isEmpty) {
          return Center(
            child: Text(
              'No pending actions',
              style: theme.textTheme.bodyLarge,
            ),
          );
        }
        
        return ListView.builder(
          itemCount: actions.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildActionItem(context, ref, action);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Error loading offline actions')),
    );
  }
  
  Widget _buildActionItem(BuildContext context, WidgetRef ref, OfflineAction action) {
    final theme = Theme.of(context);
    final offlineQueueManager = ref.read(offlineQueueManagerProvider);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          '${_capitalizeFirst(action.type.toString().split('.').last)} ${action.resourceType}',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (action.resourceId != null)
              Text('ID: ${action.resourceId}'),
            Text('Status: ${_capitalizeFirst(action.status.toString().split('.').last)}'),
            if (action.errorMessage != null)
              Text(
                'Error: ${action.errorMessage}',
                style: TextStyle(color: Colors.red[700]),
              ),
          ],
        ),
        trailing: _buildActionControls(context, ref, action, offlineQueueManager),
      ),
    );
  }
  
  Widget _buildActionControls(
    BuildContext context, 
    WidgetRef ref, 
    OfflineAction action,
    OfflineQueueManager offlineQueueManager,
  ) {
    if (action.status == OfflineActionStatus.pending || 
        action.status == OfflineActionStatus.executing) {
      return IconButton(
        icon: const Icon(Icons.cancel_outlined),
        onPressed: () => offlineQueueManager.cancelAction(action.id),
      );
    } else if (action.status == OfflineActionStatus.failed && action.canRetry) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => offlineQueueManager.retryAction(action.id),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => offlineQueueManager.removeAction(action.id),
          ),
        ],
      );
    } else {
      return IconButton(
        icon: const Icon(Icons.delete_outline),
        onPressed: () => offlineQueueManager.removeAction(action.id),
      );
    }
  }
  
  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }
}

/// Shows a dialog with offline action details
void showOfflineActionsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Pending Sync Actions'),
      content: const SizedBox(
        width: double.maxFinite,
        height: 300,
        child: OfflineActionsList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
} 