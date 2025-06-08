import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/core/network/conflict_resolver.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_action.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/network/operation_recovery_manager.dart';

/// A mixin that provides offline support for repositories
mixin OfflineRepositoryMixin {
  /// Get the cache manager
  CacheManager get cacheManager;
  
  /// Get the offline queue manager
  OfflineQueueManager get offlineQueueManager;
  
  /// Get the connectivity service
  ConnectivityService get connectivityService;
  
  /// Get the operation recovery manager
  OperationRecoveryManager get operationRecoveryManager;
  
  /// Register resource type executors with the offline queue manager
  void registerExecutors();
  
  /// Create a resource in online or offline mode
  Future<bool> createResource<T>({
    required String resourceType,
    required Map<String, dynamic> data,
    required Future<T?> Function() onlineOperation,
    required String Function(T) getResourceId,
    required String cacheKeyPrefix,
    int priority = 0,
    RemoteDataFetcher? remoteFetcher,
    ConflictHandler? conflictHandler,
    ConflictStrategy conflictStrategy = ConflictStrategy.preferLocal,
    bool trackOperation = true,
    String? operationDescription,
  }) async {
    try {
      // Create operation record for tracking
      OperationRecord? operationRecord;
      if (trackOperation) {
        operationRecord = await operationRecoveryManager.trackOperation(
          operationType: 'create',
          resourceType: resourceType,
          description: operationDescription ?? 'Create $resourceType',
          metadata: {'cacheKeyPrefix': cacheKeyPrefix},
        );
      }
      
      if (await connectivityService.checkConnectivity()) {
        // Online mode - perform operation directly
        try {
          final result = await onlineOperation();
          
          if (result != null) {
            debugPrint('📱 OfflineRepo: Created $resourceType online');
            
            // Cache the result
            final resourceId = getResourceId(result);
            cacheManager.put(
              '$cacheKeyPrefix:$resourceId', 
              result,
            );
            
            // Mark operation as completed
            if (operationRecord != null) {
              await operationRecoveryManager.updateOperation(
                operationRecord.id, 
                OperationStatus.completed,
              );
            }
            
            return true;
          }
          
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              'Creation returned null result',
            );
          }
          
          return false;
        } catch (e) {
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              e.toString(),
            );
          }
          
          debugPrint('📱 OfflineRepo: Error creating $resourceType: $e');
          rethrow;
        }
      } else {
        // Offline mode - enqueue the operation
        final action = OfflineAction(
          type: OfflineActionType.create,
          resourceType: resourceType,
          priority: priority,
          payload: data,
        );
        
        await offlineQueueManager.enqueueAction(action);
        debugPrint('📱 OfflineRepo: Enqueued create $resourceType action for offline mode');
        
        // Update operation record with action ID
        if (operationRecord != null) {
          await operationRecoveryManager.updateOperation(
            operationRecord.id,
            OperationStatus.interrupted,
            'Operation queued for execution when online',
          );
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('📱 OfflineRepo: Error creating $resourceType: $e');
      return false;
    }
  }
  
  /// Update a resource in online or offline mode
  Future<bool> updateResource<T>({
    required String resourceType,
    required String resourceId,
    required Map<String, dynamic> data,
    required Future<T?> Function() onlineOperation,
    required String cacheKeyPrefix,
    int priority = 0,
    RemoteDataFetcher? remoteFetcher,
    ConflictHandler? conflictHandler,
    ConflictStrategy conflictStrategy = ConflictStrategy.preferLocal,
    bool trackOperation = true,
    String? operationDescription,
  }) async {
    try {
      // Create operation record for tracking
      OperationRecord? operationRecord;
      if (trackOperation) {
        operationRecord = await operationRecoveryManager.trackOperation(
          operationType: 'update',
          resourceType: resourceType,
          resourceId: resourceId,
          description: operationDescription ?? 'Update $resourceType: $resourceId',
          metadata: {
            'cacheKeyPrefix': cacheKeyPrefix,
            'data': data,
          },
        );
      }
      
      if (await connectivityService.checkConnectivity()) {
        // Online mode - perform operation directly
        try {
          final result = await onlineOperation();
          
          if (result != null) {
            debugPrint('📱 OfflineRepo: Updated $resourceType:$resourceId online');
            
            // Update cache
            cacheManager.put(
              '$cacheKeyPrefix:$resourceId', 
              result,
            );
            
            // Mark operation as completed
            if (operationRecord != null) {
              await operationRecoveryManager.updateOperation(
                operationRecord.id, 
                OperationStatus.completed,
              );
            }
            
            return true;
          }
          
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              'Update returned null result',
            );
          }
          
          return false;
        } catch (e) {
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              e.toString(),
            );
          }
          
          debugPrint('📱 OfflineRepo: Error updating $resourceType:$resourceId: $e');
          rethrow;
        }
      } else {
        // Offline mode - enqueue the operation
        final action = OfflineAction(
          type: OfflineActionType.update,
          resourceType: resourceType,
          resourceId: resourceId,
          priority: priority,
          payload: data,
        );
        
        await offlineQueueManager.enqueueAction(action);
        debugPrint('📱 OfflineRepo: Enqueued update $resourceType:$resourceId action for offline mode');
        
        // Apply optimistic update to cache if item exists
        final cachedItem = cacheManager.get<T>('$cacheKeyPrefix:$resourceId');
        if (cachedItem != null) {
          // Store the offline update so UI can reflect it
          cacheManager.put(
            '$cacheKeyPrefix:$resourceId:offlineUpdate', 
            data,
          );
        }
        
        // Update operation record with action ID
        if (operationRecord != null) {
          await operationRecoveryManager.updateOperation(
            operationRecord.id,
            OperationStatus.interrupted,
            'Operation queued for execution when online',
          );
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('📱 OfflineRepo: Error updating $resourceType:$resourceId: $e');
      return false;
    }
  }
  
  /// Delete a resource in online or offline mode
  Future<bool> deleteResource({
    required String resourceType,
    required String resourceId,
    required Future<bool> Function() onlineOperation,
    required String cacheKeyPrefix,
    int priority = 0,
    RemoteDataFetcher? remoteFetcher,
    ConflictHandler? conflictHandler,
    ConflictStrategy conflictStrategy = ConflictStrategy.preferLocal,
    bool trackOperation = true,
    String? operationDescription,
  }) async {
    try {
      // Create operation record for tracking
      OperationRecord? operationRecord;
      if (trackOperation) {
        operationRecord = await operationRecoveryManager.trackOperation(
          operationType: 'delete',
          resourceType: resourceType,
          resourceId: resourceId,
          description: operationDescription ?? 'Delete $resourceType: $resourceId',
          metadata: {'cacheKeyPrefix': cacheKeyPrefix},
        );
      }
      
      if (await connectivityService.checkConnectivity()) {
        // Online mode - perform operation directly
        try {
          final success = await onlineOperation();
          
          if (success) {
            debugPrint('📱 OfflineRepo: Deleted $resourceType:$resourceId online');
            
            // Invalidate cache
            cacheManager.invalidateCache('$cacheKeyPrefix:$resourceId');
            
            // Mark operation as completed
            if (operationRecord != null) {
              await operationRecoveryManager.updateOperation(
                operationRecord.id, 
                OperationStatus.completed,
              );
            }
            
            return true;
          }
          
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              'Deletion returned false',
            );
          }
          
          return false;
        } catch (e) {
          // Mark operation as failed
          if (operationRecord != null) {
            await operationRecoveryManager.updateOperation(
              operationRecord.id, 
              OperationStatus.failed,
              e.toString(),
            );
          }
          
          debugPrint('📱 OfflineRepo: Error deleting $resourceType:$resourceId: $e');
          rethrow;
        }
      } else {
        // Offline mode - enqueue the operation
        final action = OfflineAction(
          type: OfflineActionType.delete,
          resourceType: resourceType,
          resourceId: resourceId,
          priority: priority,
          payload: {'id': resourceId},
        );
        
        await offlineQueueManager.enqueueAction(action);
        debugPrint('📱 OfflineRepo: Enqueued delete $resourceType:$resourceId action for offline mode');
        
        // Mark item as deleted in cache
        cacheManager.put(
          '$cacheKeyPrefix:$resourceId:markedForDeletion', 
          true,
        );
        
        // Update operation record with action ID
        if (operationRecord != null) {
          await operationRecoveryManager.updateOperation(
            operationRecord.id,
            OperationStatus.interrupted,
            'Operation queued for execution when online',
          );
        }
        
        return true;
      }
    } catch (e) {
      debugPrint('📱 OfflineRepo: Error deleting $resourceType:$resourceId: $e');
      return false;
    }
  }
  
  /// Register recovery handlers for operations
  void registerRecoveryHandlers() {
    // Register create operation handler
    operationRecoveryManager.registerRetryHandler('create', _recoverCreateOperation);
    
    // Register update operation handler
    operationRecoveryManager.registerRetryHandler('update', _recoverUpdateOperation);
    
    // Register delete operation handler
    operationRecoveryManager.registerRetryHandler('delete', _recoverDeleteOperation);
    
    debugPrint('📱 OfflineRepo: Registered operation recovery handlers');
  }
  
  /// Handle recovery of create operations
  Future<bool> _recoverCreateOperation(OperationRecord record) async {
    debugPrint('📱 OfflineRepo: Attempting to recover create operation for ${record.resourceType}');
    
    // If there's no cached function to handle this type, fail
    if (!_resolveCreateFunctionForType(record.resourceType)) {
      return false;
    }
    
    // We can't do much without the original data, so this is mostly for tracking
    final data = record.metadata;
    if (data.isEmpty) {
      debugPrint('📱 OfflineRepo: No metadata found for create operation');
      return false;
    }
    
    // Create a new action for this operation
    final action = OfflineAction(
      type: OfflineActionType.create,
      resourceType: record.resourceType,
      payload: data,
      priority: 10, // High priority for recovery
    );
    
    await offlineQueueManager.enqueueAction(action);
    return true;
  }
  
  /// Handle recovery of update operations
  Future<bool> _recoverUpdateOperation(OperationRecord record) async {
    if (record.resourceId == null) {
      debugPrint('📱 OfflineRepo: Missing resource ID for update operation');
      return false;
    }
    
    debugPrint('📱 OfflineRepo: Attempting to recover update operation for ${record.resourceType}:${record.resourceId}');
    
    // If there's no cached function to handle this type, fail
    if (!_resolveUpdateFunctionForType(record.resourceType)) {
      return false;
    }
    
    // Get the data from the operation metadata
    final data = record.metadata['data'];
    if (data == null) {
      debugPrint('📱 OfflineRepo: No data found in update operation metadata');
      return false;
    }
    
    // Create a new action for this operation
    final action = OfflineAction(
      type: OfflineActionType.update,
      resourceType: record.resourceType,
      resourceId: record.resourceId,
      payload: data is Map<String, dynamic> ? data : {},
      priority: 10, // High priority for recovery
    );
    
    await offlineQueueManager.enqueueAction(action);
    return true;
  }
  
  /// Handle recovery of delete operations
  Future<bool> _recoverDeleteOperation(OperationRecord record) async {
    if (record.resourceId == null) {
      debugPrint('📱 OfflineRepo: Missing resource ID for delete operation');
      return false;
    }
    
    debugPrint('📱 OfflineRepo: Attempting to recover delete operation for ${record.resourceType}:${record.resourceId}');
    
    // If there's no cached function to handle this type, fail
    if (!_resolveDeleteFunctionForType(record.resourceType)) {
      return false;
    }
    
    // Create a new action for this operation
    final action = OfflineAction(
      type: OfflineActionType.delete,
      resourceType: record.resourceType,
      resourceId: record.resourceId,
      payload: {'id': record.resourceId},
      priority: 10, // High priority for recovery
    );
    
    await offlineQueueManager.enqueueAction(action);
    return true;
  }
  
  /// Resolve update function for resource type
  bool _resolveUpdateFunctionForType(String resourceType) {
    // Subclasses should override this to provide specific recovery logic
    return false;
  }
  
  /// Resolve create function for resource type
  bool _resolveCreateFunctionForType(String resourceType) {
    // Subclasses should override this to provide specific recovery logic
    return false;
  }
  
  /// Resolve delete function for resource type
  bool _resolveDeleteFunctionForType(String resourceType) {
    // Subclasses should override this to provide specific recovery logic
    return false;
  }
  
  /// Register an executor with conflict resolution support
  void registerExecutorWithConflictResolution<T>({
    required String resourceType,
    required ActionExecutor executor,
    required RemoteDataFetcher remoteFetcher,
    ConflictHandler? conflictHandler,
    ConflictStrategy conflictStrategy = ConflictStrategy.preferRecent,
    Map<String, dynamic> Function(T, Map<String, dynamic>)? applyUpdates,
  }) {
    offlineQueueManager.registerExecutor(
      resourceType,
      executor,
      remoteFetcher: remoteFetcher,
      conflictHandler: conflictHandler,
      conflictStrategy: conflictStrategy,
    );
    
    debugPrint('📱 OfflineRepo: Registered executor with conflict resolution for $resourceType');
  }
  
  /// Check if an item has pending offline operations
  bool hasOfflineUpdates<T>({
    required String resourceId,
    required String cacheKeyPrefix,
  }) {
    final markedForDeletion = cacheManager.get<bool>('$cacheKeyPrefix:$resourceId:markedForDeletion');
    final offlineUpdate = cacheManager.get<Map<String, dynamic>>('$cacheKeyPrefix:$resourceId:offlineUpdate');
    
    return markedForDeletion == true || offlineUpdate != null;
  }
  
  /// Get the optimistic version of an item, applying any offline updates
  T? getWithOfflineUpdates<T>({
    required String resourceId,
    required String cacheKeyPrefix,
    required T? Function(T, Map<String, dynamic>) applyOfflineUpdate,
  }) {
    final cachedItem = cacheManager.get<T>('$cacheKeyPrefix:$resourceId');
    if (cachedItem == null) {
      return null;
    }
    
    final markedForDeletion = cacheManager.get<bool>('$cacheKeyPrefix:$resourceId:markedForDeletion');
    if (markedForDeletion == true) {
      return null; // Item is marked for deletion, so return null
    }
    
    final offlineUpdate = cacheManager.get<Map<String, dynamic>>('$cacheKeyPrefix:$resourceId:offlineUpdate');
    if (offlineUpdate != null) {
      return applyOfflineUpdate(cachedItem, offlineUpdate);
    }
    
    return cachedItem;
  }
  
  /// Create a custom merge function for resolving conflicts
  ConflictHandler createMergeHandler<T>({
    required String Function(T) getResourceId,
    required T Function(Map<String, dynamic>) fromJson,
    required Map<String, dynamic> Function(T) toJson,
    required T Function(T local, T remote) mergeEntities,
    required String cacheKeyPrefix,
  }) {
    return (action, remoteData, resolver) async {
      if (remoteData == null) {
        return action.payload;
      }
      
      try {
        // Convert JSON to entities
        final localEntity = fromJson(action.payload);
        final remoteEntity = fromJson(remoteData);
        
        // Merge the entities using the provided merger function
        final mergedEntity = mergeEntities(localEntity, remoteEntity);
        
        // Convert back to JSON
        final mergedData = toJson(mergedEntity);
        
        // If this is an update operation, also update the cache
        if (action.type == OfflineActionType.update && action.resourceId != null) {
          final resourceId = action.resourceId!;
          
          // Update the cache with the merged entity
          cacheManager.put('$cacheKeyPrefix:$resourceId', mergedEntity);
          
          // Clear the offline update marker since we're applying the changes
          cacheManager.invalidateCache('$cacheKeyPrefix:$resourceId:offlineUpdate');
        }
        
        debugPrint('📱 OfflineRepo: Created merged version for ${action.resourceType}:${action.resourceId}');
        return mergedData;
      } catch (e) {
        debugPrint('📱 OfflineRepo: Error merging entities: $e');
        return action.payload; // Fall back to local data
      }
    };
  }
}

/// Helper to create an offline-aware repository provider
Provider<T> createOfflineRepositoryProvider<T>({
  required T Function(
    OfflineQueueManager, 
    ConnectivityService, 
    CacheManager, 
    ConflictResolver, 
    OperationRecoveryManager,
    Ref
  ) create,
  required String name,
}) {
  return Provider<T>((ref) {
    final offlineQueueManager = ref.watch(offlineQueueManagerProvider);
    final connectivityService = ref.watch(connectivityServiceProvider);
    final cacheManager = ref.watch(cacheManagerProvider);
    final conflictResolver = ref.watch(conflictResolverProvider);
    final operationRecoveryManager = ref.watch(operationRecoveryManagerProvider);
    
    final repository = create(
      offlineQueueManager, 
      connectivityService, 
      cacheManager, 
      conflictResolver, 
      operationRecoveryManager,
      ref
    );
    
    // Register executors if the repository supports it
    if (repository is OfflineRepositoryMixin) {
      (repository as OfflineRepositoryMixin).registerExecutors();
      (repository as OfflineRepositoryMixin).registerRecoveryHandlers();
    }
    
    return repository;
  }, name: name);
} 