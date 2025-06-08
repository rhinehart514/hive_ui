import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';

/// A builder that handles optimistic UI updates for actions that may occur while offline
class OptimisticActionBuilder<T> extends ConsumerWidget {
  /// The resource type (e.g., 'profile', 'event')
  final String resourceType;
  
  /// The resource ID
  final String resourceId;
  
  /// Current remote data
  final T remoteData;
  
  /// Function to generate optimistic data for create operations
  final T Function(OfflineAction action)? createDataBuilder;
  
  /// Function to generate optimistic data for update operations
  final T Function(T currentData, OfflineAction action)? updateDataBuilder;
  
  /// Function to determine if the data should be considered deleted
  final bool Function(OfflineAction action)? shouldShowAsDeleted;
  
  /// Builder function for the widget
  final Widget Function(BuildContext context, T displayData, bool isPending) builder;
  
  /// Widget to show when the data is considered deleted
  final Widget? deletedPlaceholder;
  
  /// Constructor
  const OptimisticActionBuilder({
    Key? key,
    required this.resourceType,
    required this.resourceId,
    required this.remoteData,
    required this.builder,
    this.createDataBuilder,
    this.updateDataBuilder,
    this.shouldShowAsDeleted,
    this.deletedPlaceholder,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    
    // Find any pending actions for this specific resource
    final resourceActions = pendingActions.where((action) => 
      action.resourceType == resourceType && 
      action.resourceId == resourceId
    ).toList();
    
    if (resourceActions.isEmpty) {
      // No pending actions, use remote data
      return builder(context, remoteData, false);
    }
    
    // Check if there's a delete action
    final deleteAction = resourceActions.firstWhere(
      (action) => action.type == OfflineActionType.delete,
      orElse: () => resourceActions.firstWhere(
        (action) => shouldShowAsDeleted != null && shouldShowAsDeleted!(action),
        orElse: () => resourceActions[0],
      ),
    );
    
    if (deleteAction.type == OfflineActionType.delete || 
        (shouldShowAsDeleted != null && shouldShowAsDeleted!(deleteAction))) {
      // Item is being deleted
      return deletedPlaceholder ?? const SizedBox.shrink();
    }
    
    // Sort actions by creation time to apply them in sequence
    resourceActions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    
    // Apply pending actions to the data
    T optimisticData = remoteData;
    for (final action in resourceActions) {
      switch (action.type) {
        case OfflineActionType.create:
          if (createDataBuilder != null) {
            optimisticData = createDataBuilder!(action);
          }
          break;
        case OfflineActionType.update:
          if (updateDataBuilder != null) {
            optimisticData = updateDataBuilder!(optimisticData, action);
          }
          break;
        case OfflineActionType.delete:
          // Already handled above
          break;
        case OfflineActionType.custom:
          // For custom actions, we would need specific handling
          // Usually handled through updateDataBuilder
          if (updateDataBuilder != null) {
            optimisticData = updateDataBuilder!(optimisticData, action);
          }
          break;
      }
    }
    
    // Build with optimistic data and indicate that it's pending
    return builder(context, optimisticData, true);
  }
}

/// A builder that handles optimistic UI updates for lists of items
class OptimisticListBuilder<T> extends ConsumerWidget {
  /// The resource type (e.g., 'profile', 'event')
  final String resourceType;
  
  /// Current remote items list
  final List<T> remoteItems;
  
  /// Function to extract the ID from an item
  final String Function(T item) itemIdExtractor;
  
  /// Function to generate optimistic data for create operations
  final T Function(OfflineAction action) createItemBuilder;
  
  /// Function to generate optimistic data for update operations
  final T Function(T currentItem, OfflineAction action) updateItemBuilder;
  
  /// Function to determine if the data should be shown (filter function)
  final bool Function(T item, List<OfflineAction> actions)? filterItem;
  
  /// Builder function for the widget
  final Widget Function(BuildContext context, List<T> displayItems, Set<String> pendingItemIds) builder;
  
  /// Constructor
  const OptimisticListBuilder({
    Key? key,
    required this.resourceType,
    required this.remoteItems,
    required this.itemIdExtractor,
    required this.createItemBuilder,
    required this.updateItemBuilder,
    required this.builder,
    this.filterItem,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingActions = ref.watch(pendingOfflineActionsProvider);
    
    // Find actions related to this resource type
    final resourceActions = pendingActions.where((action) => 
      action.resourceType == resourceType
    ).toList();
    
    if (resourceActions.isEmpty) {
      // No pending actions, use remote data
      return builder(context, remoteItems, {});
    }
    
    // Group actions by resource ID
    final actionsByResourceId = <String, List<OfflineAction>>{};
    for (final action in resourceActions) {
      if (action.resourceId != null) {
        actionsByResourceId.putIfAbsent(action.resourceId!, () => []).add(action);
      }
    }
    
    // Create a mutable copy of the remote items
    final List<T> optimisticItems = List.from(remoteItems);
    final Set<String> pendingItemIds = {};
    
    // Process create actions first
    for (final entry in actionsByResourceId.entries) {
      final resourceId = entry.key;
      final actions = entry.value;
      
      // Check if there are any create actions
      final createAction = actions.firstWhere(
        (action) => action.type == OfflineActionType.create,
        orElse: () => actions[0],
      );
      
      if (createAction.type == OfflineActionType.create) {
        // Find existing item with this ID if it exists
        final existingIndex = optimisticItems.indexWhere(
          (item) => itemIdExtractor(item) == resourceId
        );
        
        if (existingIndex == -1) {
          // Item doesn't exist yet, create it
          final newItem = createItemBuilder(createAction);
          optimisticItems.add(newItem);
          pendingItemIds.add(resourceId);
        }
      }
    }
    
    // Now process updates and deletes
    for (int i = optimisticItems.length - 1; i >= 0; i--) {
      final item = optimisticItems[i];
      final itemId = itemIdExtractor(item);
      
      if (actionsByResourceId.containsKey(itemId)) {
        final actions = actionsByResourceId[itemId]!;
        
        // Sort actions by creation time
        actions.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        
        // Check if item should be deleted
        final deleteAction = actions.firstWhere(
          (action) => action.type == OfflineActionType.delete,
          orElse: () => actions[0],
        );
        
        if (deleteAction.type == OfflineActionType.delete) {
          // Remove item if it's being deleted
          optimisticItems.removeAt(i);
          continue;
        }
        
        // Apply update actions
        T updatedItem = item;
        for (final action in actions.where((a) => a.type == OfflineActionType.update)) {
          updatedItem = updateItemBuilder(updatedItem, action);
          pendingItemIds.add(itemId);
        }
        
        // Replace item with updated version
        if (updatedItem != item) {
          optimisticItems[i] = updatedItem;
        }
        
        // Apply filter if provided
        if (filterItem != null && !filterItem!(updatedItem, actions)) {
          optimisticItems.removeAt(i);
        }
      }
    }
    
    // Build with optimistic data and indicate which items are pending
    return builder(context, optimisticItems, pendingItemIds);
  }
} 