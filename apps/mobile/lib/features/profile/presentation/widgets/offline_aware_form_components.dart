import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/widgets/offline_action_status.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// A form field that shows pending status when being synced after offline changes
class OfflineAwareFormField extends ConsumerWidget {
  /// The resource type this field relates to (e.g., 'profile')
  final String resourceType;
  
  /// The resource ID this field relates to
  final String resourceId;
  
  /// The form field to display
  final Widget formField;
  
  /// Constructor
  const OfflineAwareFormField({
    Key? key,
    required this.resourceType,
    required this.resourceId,
    required this.formField,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    
    // Check if there are pending actions for this resource
    final hasPendingActions = pendingActions.any((action) => 
      action.resourceType == resourceType && 
      action.resourceId == resourceId
    );
    
    // Check if offline
    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result.name == 'none',
      orElse: () => true,
    );
    
    // If not pending, just return the regular form field
    if (!hasPendingActions) {
      return formField;
    }
    
    // For form fields, wrap in a stack with an indicator
    return Stack(
      children: [
        formField,
        Positioned(
          top: 0,
          right: 0,
          child: PendingActionBadge(
            isPending: true,
            color: isOffline ? Colors.red : Colors.orange,
          ),
        ),
      ],
    );
  }
}

/// A button that shows pending status when actions are being synced
class OfflineAwareButton extends ConsumerWidget {
  /// The resource type this button relates to (e.g., 'profile')
  final String resourceType;
  
  /// The resource ID this button relates to
  final String resourceId;
  
  /// Label to show when offline
  final String offlineLabel;
  
  /// Only show offline indicator when offline
  final bool showOnlyWhenOffline;
  
  /// The button's onPressed callback
  final VoidCallback? onPressed;
  
  /// The button's child widget
  final Widget child;
  
  /// Constructor
  const OfflineAwareButton({
    Key? key,
    required this.resourceType,
    required this.resourceId,
    this.offlineLabel = 'Changes will sync when online',
    this.showOnlyWhenOffline = false,
    required this.onPressed,
    required this.child,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    
    // Check if there are pending actions for this resource
    final hasPendingActions = pendingActions.any((action) => 
      action.resourceType == resourceType && 
      action.resourceId == resourceId
    );
    
    // Check if offline
    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result.name == 'none',
      orElse: () => true,
    );
    
    // Determine if we should show the pending indicator
    final showPending = hasPendingActions && (isOffline || !showOnlyWhenOffline);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              if (showPending) ...[
                const SizedBox(width: 8),
                Icon(
                  isOffline ? Icons.wifi_off : Icons.sync,
                  size: 16,
                  color: isOffline ? Colors.red.shade800 : Colors.black54,
                ),
              ]
            ],
          ),
        ),
        if (showPending)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: PendingActionText(
              isPending: true,
              style: OfflineStatusTextStyle.subtle,
              pendingText: isOffline ? offlineLabel : 'Syncing...',
            ),
          ),
      ],
    );
  }
}

/// A widget that shows a status indicator for offline resources
class OfflineStatusIndicator extends ConsumerWidget {
  /// The resource type this indicator relates to (e.g., 'profile')
  final String resourceType;
  
  /// The resource ID this indicator relates to
  final String? resourceId;
  
  /// Label to show when syncing
  final String syncingLabel;
  
  /// Label to show when offline
  final String offlineLabel;
  
  /// Only show when offline
  final bool showOnlyWhenOffline;
  
  /// Constructor
  const OfflineStatusIndicator({
    Key? key,
    required this.resourceType,
    this.resourceId,
    this.syncingLabel = 'Syncing...',
    this.offlineLabel = 'Will update when online',
    this.showOnlyWhenOffline = false,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    final connectivityStatus = ref.watch(connectivityStatusProvider);
    
    // Check if there are pending actions for this resource
    final hasPendingActions = pendingActions.any((action) => 
      action.resourceType == resourceType && 
      (resourceId == null || action.resourceId == resourceId)
    );
    
    // Check if offline
    final isOffline = connectivityStatus.maybeWhen(
      data: (result) => result.name == 'none',
      orElse: () => true,
    );
    
    // If no pending actions or we're online and only showing when offline, hide
    if (!hasPendingActions || (!isOffline && showOnlyWhenOffline)) {
      return const SizedBox.shrink();
    }
    
    final message = isOffline ? offlineLabel : syncingLabel;
    final icon = isOffline ? Icons.wifi_off : Icons.sync;
    final color = isOffline ? Colors.red : Colors.orange;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            message,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
} 