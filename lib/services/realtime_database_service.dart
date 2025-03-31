import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service for interacting with Firebase Realtime Database
class RealtimeDatabaseService {
  final FirebaseDatabase _database;

  // For caching complex query results
  final Map<String, dynamic> _queryCache = {};
  final Map<String, DateTime> _queryCacheTimestamps = {};

  // Cache expiration time
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Constructor
  RealtimeDatabaseService({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance {
    _initDatabase();
  }

  /// Initialize the database
  void _initDatabase() {
    try {
      // Enable persistence for offline support
      _database.setPersistenceEnabled(true);

      // Set cache size (default is 10MB)
      _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB

      debugPrint('Realtime Database initialized with persistence enabled');
    } catch (e) {
      debugPrint('Error setting up Realtime Database persistence: $e');
    }
  }

  /// Get data from a specific path
  Future<dynamic> getData(String path) async {
    try {
      final ref = _database.ref(path);
      final snapshot = await ref.get();

      if (snapshot.exists) {
        return snapshot.value;
      } else {
        debugPrint('No data available at path: $path');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting data from $path: $e');
      rethrow;
    }
  }

  /// Set data at a specific path (overwrites existing data)
  Future<void> setData(String path, dynamic data) async {
    try {
      final ref = _database.ref(path);
      await ref.set(data);

      // Clear any cached data for this path
      _clearCacheForPath(path);
    } catch (e) {
      debugPrint('Error setting data at $path: $e');
      rethrow;
    }
  }

  /// Update data at a specific path (only changes specified fields)
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      final ref = _database.ref(path);
      await ref.update(data);

      // Clear any cached data for this path
      _clearCacheForPath(path);
    } catch (e) {
      debugPrint('Error updating data at $path: $e');
      rethrow;
    }
  }

  /// Push new data to a list at the specified path (generates unique key)
  Future<String?> pushData(String path, dynamic data) async {
    try {
      final ref = _database.ref(path);
      final newRef = ref.push();
      await newRef.set(data);

      // Clear any cached data for this path
      _clearCacheForPath(path);

      return newRef.key;
    } catch (e) {
      debugPrint('Error pushing data to $path: $e');
      rethrow;
    }
  }

  /// Delete data at a specific path
  Future<void> deleteData(String path) async {
    try {
      final ref = _database.ref(path);
      await ref.remove();

      // Clear any cached data for this path
      _clearCacheForPath(path);
    } catch (e) {
      debugPrint('Error deleting data at $path: $e');
      rethrow;
    }
  }

  /// Listen to data changes at a specific path
  Stream<dynamic> listenToData(String path) {
    final ref = _database.ref(path);
    return ref.onValue.map((event) {
      final snapshot = event.snapshot;
      if (snapshot.exists) {
        return snapshot.value;
      } else {
        return null;
      }
    });
  }

  /// Listen to child added events at a specific path
  Stream<DatabaseEvent> listenToChildAdded(String path) {
    final ref = _database.ref(path);
    return ref.onChildAdded;
  }

  /// Listen to child changed events at a specific path
  Stream<DatabaseEvent> listenToChildChanged(String path) {
    final ref = _database.ref(path);
    return ref.onChildChanged;
  }

  /// Listen to child removed events at a specific path
  Stream<DatabaseEvent> listenToChildRemoved(String path) {
    final ref = _database.ref(path);
    return ref.onChildRemoved;
  }

  /// Query data with specific parameters (orderBy, limitTo, etc.)
  Future<List<Map<String, dynamic>>> queryData(
    String path, {
    String? orderByChild,
    dynamic startAt,
    dynamic endAt,
    dynamic equalTo,
    int? limitToFirst,
    int? limitToLast,
    bool useCaching = true,
  }) async {
    try {
      // Create a cache key based on query parameters
      final cacheKey = _generateCacheKey(
        path,
        orderByChild: orderByChild,
        startAt: startAt,
        endAt: endAt,
        equalTo: equalTo,
        limitToFirst: limitToFirst,
        limitToLast: limitToLast,
      );

      // Check if valid cached results exist
      if (useCaching && _isQueryCacheValid(cacheKey)) {
        debugPrint('Using cached results for query: $cacheKey');
        return List<Map<String, dynamic>>.from(_queryCache[cacheKey]);
      }

      // Build the query
      DatabaseReference ref = _database.ref(path);
      Query query = ref;

      if (orderByChild != null) {
        query = query.orderByChild(orderByChild);
      }

      if (startAt != null) {
        query = query.startAt(startAt);
      }

      if (endAt != null) {
        query = query.endAt(endAt);
      }

      if (equalTo != null) {
        query = query.equalTo(equalTo);
      }

      if (limitToFirst != null) {
        query = query.limitToFirst(limitToFirst);
      }

      if (limitToLast != null) {
        query = query.limitToLast(limitToLast);
      }

      // Execute the query
      final snapshot = await query.get();

      if (!snapshot.exists) {
        return [];
      }

      // Convert the snapshot to a list of maps with keys
      final List<Map<String, dynamic>> result = [];
      final Map<dynamic, dynamic>? values =
          snapshot.value as Map<dynamic, dynamic>?;

      if (values != null) {
        values.forEach((key, value) {
          if (value is Map) {
            final Map<String, dynamic> item =
                Map<String, dynamic>.from(value);
            item['key'] = key;
            result.add(item);
          }
        });
      }

      // Cache the results if caching is enabled
      if (useCaching) {
        _queryCache[cacheKey] = List<Map<String, dynamic>>.from(result);
        _queryCacheTimestamps[cacheKey] = DateTime.now();
      }

      return result;
    } catch (e) {
      debugPrint('Error querying data at $path: $e');
      return [];
    }
  }

  /// Run a transaction on a specific path for atomic operations
  Future<TransactionResult> runTransaction(
      String path, dynamic Function(Object? current) update) async {
    try {
      final ref = _database.ref(path);
      final result = await ref.runTransaction((currentData) {
        return update(currentData);
      });

      // Clear any cached data for this path
      _clearCacheForPath(path);

      return result;
    } catch (e) {
      debugPrint('Error running transaction at $path: $e');
      rethrow;
    }
  }

  /// Clear all caches
  void clearAllCaches() {
    _queryCache.clear();
    _queryCacheTimestamps.clear();
  }

  /// Check if query cache is valid
  bool _isQueryCacheValid(String cacheKey) {
    if (!_queryCache.containsKey(cacheKey) ||
        !_queryCacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _queryCacheTimestamps[cacheKey]!;
    final age = DateTime.now().difference(timestamp);

    return age < _cacheDuration;
  }

  /// Generate a cache key for a query
  String _generateCacheKey(
    String path, {
    String? orderByChild,
    dynamic startAt,
    dynamic endAt,
    dynamic equalTo,
    int? limitToFirst,
    int? limitToLast,
  }) {
    return [
      path,
      orderByChild,
      startAt?.toString(),
      endAt?.toString(),
      equalTo?.toString(),
      limitToFirst?.toString(),
      limitToLast?.toString(),
    ].join('-');
  }

  /// Clear cache for a specific path and its children
  void _clearCacheForPath(String path) {
    _queryCache.removeWhere((key, _) => key.startsWith(path));
    _queryCacheTimestamps.removeWhere((key, _) => key.startsWith(path));
  }
}

/// Provider for the Realtime Database service
final realtimeDatabaseServiceProvider =
    Provider<RealtimeDatabaseService>((ref) {
  return RealtimeDatabaseService();
});
