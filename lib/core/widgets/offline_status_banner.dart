import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/network/operation_recovery_manager.dart';

/// A banner widget that displays the network status and any interrupted operations
class OfflineStatusBanner extends ConsumerWidget {
  /// Constructor
  const OfflineStatusBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    final interruptedOperations = ref.watch(interruptedOperationsProvider);
    
    // No banner needed if online and no pending/interrupted operations
    if (connectivityStatus.maybeWhen(
      data: (result) => result == ConnectivityResult.wifi || 
                  result == ConnectivityResult.mobile || 
                  result == ConnectivityResult.ethernet,
      orElse: () => false,
    ) && pendingActions.isEmpty && interruptedOperations.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Show a banner with the appropriate message
    return Container(
      color: _getBannerColor(connectivityStatus, pendingActions, interruptedOperations),
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                _getStatusIcon(connectivityStatus, pendingActions, interruptedOperations),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    _getBannerMessage(connectivityStatus, pendingActions, interruptedOperations),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (pendingActions.isNotEmpty || interruptedOperations.isNotEmpty)
                  TextButton(
                    onPressed: () => _showOperationsDialog(context, ref),
                    child: const Text(
                      'View',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
              ],
            ),
            if (interruptedOperations.isNotEmpty && connectivityStatus.maybeWhen(
              data: (result) => result == ConnectivityResult.wifi || 
                          result == ConnectivityResult.mobile || 
                          result == ConnectivityResult.ethernet,
              orElse: () => false,
            ))
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                    ),
                    onPressed: () => _retryAllOperations(context, ref),
                    child: const Text('Retry All Interrupted Operations'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// Get the banner color based on the current status
  Color _getBannerColor(
    AsyncValue<ConnectivityResult> connectivityStatus,
    List<OfflineAction> pendingActions,
    List<OperationRecord> interruptedOperations,
  ) {
    // Offline - red
    if (connectivityStatus.maybeWhen(
      data: (result) => result == ConnectivityResult.none,
      orElse: () => false,
    )) {
      return Colors.red.shade800;
    }
    
    // Has interrupted operations - orange
    if (interruptedOperations.isNotEmpty) {
      return Colors.orange.shade800;
    }
    
    // Has pending actions - blue
    if (pendingActions.isNotEmpty) {
      return Colors.blue.shade800;
    }
    
    // Default
    return Colors.grey.shade800;
  }
  
  /// Get the status icon based on the current status
  Widget _getStatusIcon(
    AsyncValue<ConnectivityResult> connectivityStatus,
    List<OfflineAction> pendingActions,
    List<OperationRecord> interruptedOperations,
  ) {
    // Offline
    if (connectivityStatus.maybeWhen(
      data: (result) => result == ConnectivityResult.none,
      orElse: () => false,
    )) {
      return const Icon(Icons.signal_wifi_off, color: Colors.white);
    }
    
    // Has interrupted operations
    if (interruptedOperations.isNotEmpty) {
      return const Icon(Icons.warning_amber_rounded, color: Colors.white);
    }
    
    // Has pending actions
    if (pendingActions.isNotEmpty) {
      return const Icon(Icons.cloud_upload, color: Colors.white);
    }
    
    // Default
    return const Icon(Icons.signal_wifi_4_bar, color: Colors.white);
  }
  
  /// Get the banner message based on the current status
  String _getBannerMessage(
    AsyncValue<ConnectivityResult> connectivityStatus,
    List<OfflineAction> pendingActions,
    List<OperationRecord> interruptedOperations,
  ) {
    // Offline
    if (connectivityStatus.maybeWhen(
      data: (result) => result == ConnectivityResult.none,
      orElse: () => false,
    )) {
      if (pendingActions.isNotEmpty) {
        return 'You are offline. ${pendingActions.length} ${pendingActions.length == 1 ? 'action is' : 'actions are'} queued.';
      }
      return 'You are offline. Changes will be saved and synced when you reconnect.';
    }
    
    // Has interrupted operations
    if (interruptedOperations.isNotEmpty) {
      return '${interruptedOperations.length} ${interruptedOperations.length == 1 ? 'operation was' : 'operations were'} interrupted. Tap to retry.';
    }
    
    // Has pending actions
    if (pendingActions.isNotEmpty) {
      return 'Syncing ${pendingActions.length} ${pendingActions.length == 1 ? 'change' : 'changes'}...';
    }
    
    // Default
    return 'Online';
  }
  
  /// Show a dialog with details about pending and interrupted operations
  void _showOperationsDialog(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.read(pendingOfflineActionsProvider);
    final interruptedOperations = ref.read(interruptedOperationsProvider);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pending Operations'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (interruptedOperations.isNotEmpty) ...[
                  const Text(
                    'Interrupted Operations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ...interruptedOperations.map((op) => OperationStatusItem(
                    operation: op,
                    onRetry: () => _retryOperation(context, ref, op),
                  )),
                  const Divider(),
                ],
                if (pendingActions.isNotEmpty) ...[
                  const Text(
                    'Pending Operations:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8.0),
                  ...pendingActions.map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text('• ${_formatActionDescription(action)}'),
                  )),
                ],
              ],
            ),
          ),
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
  
  /// Format an action description for display
  String _formatActionDescription(OfflineAction action) {
    final type = action.type.toString().split('.').last;
    final resource = action.resourceType;
    final id = action.resourceId ?? '';
    
    return '$type $resource ${id.isNotEmpty ? '($id)' : ''}';
  }
  
  /// Retry a specific operation
  Future<void> _retryOperation(BuildContext context, WidgetRef ref, OperationRecord operation) async {
    Navigator.of(context).pop(); // Close the dialog
    
    final operationRecoveryManager = ref.read(operationRecoveryManagerProvider);
    final success = await operationRecoveryManager.retryOperation(operation.id);
    
    // Show a snackbar with the result
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success 
                ? 'Operation retried successfully' 
                : 'Failed to retry operation',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
  
  /// Retry all interrupted operations
  Future<void> _retryAllOperations(BuildContext context, WidgetRef ref) async {
    final operationRecoveryManager = ref.read(operationRecoveryManagerProvider);
    final interruptedOperations = ref.read(interruptedOperationsProvider);
    
    int successCount = 0;
    
    for (final operation in interruptedOperations) {
      final success = await operationRecoveryManager.retryOperation(operation.id);
      if (success) {
        successCount++;
      }
    }
    
    // Show a snackbar with the results
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Retried ${interruptedOperations.length} operations: $successCount succeeded',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

/// A widget to display a single operation status item
class OperationStatusItem extends StatelessWidget {
  /// The operation to display
  final OperationRecord operation;
  
  /// Callback when retry is pressed
  final VoidCallback onRetry;
  
  /// Constructor
  const OperationStatusItem({
    Key? key,
    required this.operation,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  operation.description,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (operation.errorMessage != null)
                  Text(
                    operation.errorMessage!,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontSize: 12.0,
                    ),
                  ),
                Text(
                  'Attempt ${operation.retryCount + 1} of ${operation.maxRetries + 1}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (operation.canRetry)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
} 