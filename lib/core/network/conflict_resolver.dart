import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/core/network/offline_action.dart';

/// Strategy to use when resolving conflicts
enum ConflictStrategy {
  /// Always use the local (offline) version
  preferLocal,
  
  /// Always use the remote (server) version
  preferRemote,
  
  /// Use the most recent version based on timestamps
  preferRecent,
  
  /// Merge the data with custom logic
  customMerge,
}

/// Result of a conflict resolution
enum ConflictResolutionResult {
  /// The local version was used
  usedLocal,
  
  /// The remote version was used
  usedRemote,
  
  /// A merged version was created
  merged,
  
  /// The conflict could not be resolved
  unresolved,
  
  /// No conflict was detected
  noConflict,
}

/// A class to handle conflicts between local and remote data
class ConflictResolver {
  final CacheManager _cacheManager;
  
  /// Constructor
  ConflictResolver(this._cacheManager);
  
  /// Resolve a conflict for a specific offline action and remote data
  /// 
  /// [action] The offline action containing local changes
  /// [remoteData] The current remote data
  /// [strategy] The strategy to use for resolving conflicts
  /// [customMerge] A custom merge function, required when using [ConflictStrategy.customMerge]
  /// 
  /// Returns a tuple containing the resolution result and the resolved data
  Future<(ConflictResolutionResult, Map<String, dynamic>)> resolveConflict({
    required OfflineAction action,
    required Map<String, dynamic>? remoteData,
    required ConflictStrategy strategy,
    Map<String, dynamic> Function(Map<String, dynamic> local, Map<String, dynamic> remote)? customMerge,
  }) async {
    final localData = action.payload;
    
    // If remote data is null, there's no conflict - use local data
    if (remoteData == null) {
      return (ConflictResolutionResult.usedLocal, localData);
    }
    
    // If there's no conflict between the data, use local data
    if (!_hasConflict(localData, remoteData)) {
      return (ConflictResolutionResult.noConflict, localData);
    }
    
    debugPrint('🔄 ConflictResolver: Detected conflict for ${action.resourceType}:${action.resourceId}');
    
    switch (strategy) {
      case ConflictStrategy.preferLocal:
        debugPrint('🔄 ConflictResolver: Using local version (preferLocal strategy)');
        return (ConflictResolutionResult.usedLocal, localData);
        
      case ConflictStrategy.preferRemote:
        debugPrint('🔄 ConflictResolver: Using remote version (preferRemote strategy)');
        return (ConflictResolutionResult.usedRemote, remoteData);
        
      case ConflictStrategy.preferRecent:
        final resolution = _resolveByTimestamp(action, localData, remoteData);
        return resolution;
        
      case ConflictStrategy.customMerge:
        if (customMerge == null) {
          debugPrint('🔄 ConflictResolver: Missing customMerge function for customMerge strategy');
          return (ConflictResolutionResult.unresolved, localData);
        }
        
        try {
          final mergedData = customMerge(localData, remoteData);
          debugPrint('🔄 ConflictResolver: Successfully merged data using custom merge function');
          return (ConflictResolutionResult.merged, mergedData);
        } catch (e) {
          debugPrint('🔄 ConflictResolver: Error during custom merge: $e');
          return (ConflictResolutionResult.unresolved, localData);
        }
    }
  }
  
  /// Resolve a conflict based on timestamps
  (ConflictResolutionResult, Map<String, dynamic>) _resolveByTimestamp(
    OfflineAction action,
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Use the creation time of the action as the local modification time
    final localTime = action.createdAt;
    
    // Try to get the last modified timestamp from remote data
    final remoteTime = _extractTimestamp(remoteData);
    
    if (remoteTime == null || localTime.isAfter(remoteTime)) {
      debugPrint('🔄 ConflictResolver: Using local version (newer timestamp)');
      return (ConflictResolutionResult.usedLocal, localData);
    } else {
      debugPrint('🔄 ConflictResolver: Using remote version (newer timestamp)');
      return (ConflictResolutionResult.usedRemote, remoteData);
    }
  }
  
  /// Extract a timestamp from data
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    // Try common timestamp field names
    for (final field in ['updatedAt', 'updated_at', 'lastModified', 'last_modified', 'timestamp']) {
      if (data.containsKey(field)) {
        final value = data[field];
        
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (_) {}
        } else if (value is DateTime) {
          return value;
        } else if (value is int) {
          // Assume milliseconds since epoch
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
      }
    }
    
    return null;
  }
  
  /// Check if there's a conflict between local and remote data
  bool _hasConflict(Map<String, dynamic> local, Map<String, dynamic> remote) {
    // Get the set of keys that are in both maps
    final commonKeys = <String>{};
    
    for (final key in local.keys) {
      if (remote.containsKey(key)) {
        commonKeys.add(key);
      }
    }
    
    // Compare values for common keys, ignoring timestamp fields
    for (final key in commonKeys) {
      // Skip timestamp fields
      if (['updatedAt', 'updated_at', 'lastModified', 'last_modified', 'timestamp', 'createdAt', 'created_at'].contains(key)) {
        continue;
      }
      
      if (!_areValuesEqual(local[key], remote[key])) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Check if two values are equal
  bool _areValuesEqual(dynamic a, dynamic b) {
    if (a == null && b == null) {
      return true;
    }
    
    if (a == null || b == null) {
      return false;
    }
    
    if (a is Map && b is Map) {
      // Convert to Map<String, dynamic> for comparison
      final mapA = Map<String, dynamic>.from(a);
      final mapB = Map<String, dynamic>.from(b);
      
      return _hasConflict(mapA, mapB) == false;
    }
    
    if (a is List && b is List) {
      if (a.length != b.length) {
        return false;
      }
      
      for (var i = 0; i < a.length; i++) {
        if (!_areValuesEqual(a[i], b[i])) {
          return false;
        }
      }
      
      return true;
    }
    
    return a == b;
  }
  
  /// Create a smart merge of two objects with field-level conflict resolution
  /// This is a more advanced merge that handles lists, nested objects, and allows
  /// field-specific resolution strategies
  Map<String, dynamic> smartMerge(
    Map<String, dynamic> local, 
    Map<String, dynamic> remote,
    {Map<String, ConflictStrategy>? fieldStrategies}
  ) {
    final result = <String, dynamic>{};
    final allKeys = <String>{...local.keys, ...remote.keys};
    
    for (final key in allKeys) {
      // If key exists only in one map, use that value
      if (!local.containsKey(key)) {
        result[key] = remote[key];
        continue;
      }
      if (!remote.containsKey(key)) {
        result[key] = local[key];
        continue;
      }
      
      // Get field-specific strategy or default to preferLocal
      final strategy = fieldStrategies?[key] ?? ConflictStrategy.preferLocal;
      
      // Handle nested objects
      if (local[key] is Map && remote[key] is Map) {
        final localMap = Map<String, dynamic>.from(local[key] as Map);
        final remoteMap = Map<String, dynamic>.from(remote[key] as Map);
        
        // Recursively merge nested objects
        result[key] = smartMerge(localMap, remoteMap, fieldStrategies: fieldStrategies);
        continue;
      }
      
      // Handle lists
      if (local[key] is List && remote[key] is List) {
        result[key] = _mergeList(
          List.from(local[key] as List), 
          List.from(remote[key] as List),
          strategy,
        );
        continue;
      }
      
      // Handle scalar values based on strategy
      switch (strategy) {
        case ConflictStrategy.preferLocal:
          result[key] = local[key];
          break;
        case ConflictStrategy.preferRemote:
          result[key] = remote[key];
          break;
        case ConflictStrategy.preferRecent:
          // For scalar values, we can't determine which is more recent without context
          // Default to local
          result[key] = local[key];
          break;
        case ConflictStrategy.customMerge:
          // For scalar values, custom merge isn't applicable
          // Default to local
          result[key] = local[key];
          break;
      }
    }
    
    return result;
  }
  
  /// Merge two lists based on the given strategy
  List<dynamic> _mergeList(
    List<dynamic> local, 
    List<dynamic> remote,
    ConflictStrategy strategy,
  ) {
    switch (strategy) {
      case ConflictStrategy.preferLocal:
        return local;
      case ConflictStrategy.preferRemote:
        return remote;
      case ConflictStrategy.preferRecent:
        // Without context, we can't determine which is more recent
        // Default to local
        return local;
      case ConflictStrategy.customMerge:
        // Try to be smart about merging lists
        return _smartMergeList(local, remote);
    }
  }
  
  /// Intelligent list merging that attempts to combine elements
  List<dynamic> _smartMergeList(List<dynamic> local, List<dynamic> remote) {
    // If the lists contain primitive values, combine them and remove duplicates
    if (local.isEmpty || remote.isEmpty) {
      return [...local, ...remote];
    }
    
    // Handle primitives by creating a union
    if (local.first is String || 
        local.first is num || 
        local.first is bool) {
      return [...{...local, ...remote}];
    }
    
    // Handle maps by looking for IDs
    if (local.first is Map && remote.first is Map) {
      return _mergeObjectLists(
        local.cast<Map<String, dynamic>>(),
        remote.cast<Map<String, dynamic>>()
      );
    }
    
    // Default: concatenate lists
    return [...local, ...remote];
  }
  
  /// Merge lists of objects by matching IDs where possible
  List<Map<String, dynamic>> _mergeObjectLists(
    List<Map<String, dynamic>> local, 
    List<Map<String, dynamic>> remote,
  ) {
    final result = <Map<String, dynamic>>[];
    final remoteByIds = <String, Map<String, dynamic>>{};
    
    // Look for common ID fields
    final idField = _findIdField(local.first);
    if (idField != null) {
      // Index remote items by ID
      for (final item in remote) {
        if (item.containsKey(idField) && item[idField] != null) {
          remoteByIds[item[idField].toString()] = item;
        } else {
          // Remote items without IDs are added as is
          result.add(item);
        }
      }
      
      // Process local items
      for (final localItem in local) {
        if (localItem.containsKey(idField) && localItem[idField] != null) {
          final id = localItem[idField].toString();
          if (remoteByIds.containsKey(id)) {
            // Merge local and remote items with the same ID
            result.add(smartMerge(localItem, remoteByIds[id]!));
            remoteByIds.remove(id);
          } else {
            // No matching remote item, add local item
            result.add(localItem);
          }
        } else {
          // Local items without IDs are added as is
          result.add(localItem);
        }
      }
      
      // Add remaining remote items
      result.addAll(remoteByIds.values);
      return result;
    }
    
    // If we can't find an ID field, concatenate and remove duplicates
    return [...local, ...remote];
  }
  
  /// Try to identify the ID field in an object
  String? _findIdField(Map<String, dynamic> item) {
    // Common ID field names
    final possibleIdFields = ['id', '_id', 'uid', 'key', 'uuid'];
    
    for (final field in possibleIdFields) {
      if (item.containsKey(field) && item[field] != null) {
        return field;
      }
    }
    
    return null;
  }
}

/// Provider for the conflict resolver
final conflictResolverProvider = Provider<ConflictResolver>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return ConflictResolver(cacheManager);
}); 