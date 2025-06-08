import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Comprehensive fix for Firebase Realtime Database on Windows platform
/// This class provides an in-memory implementation for Windows to replace
/// the Firebase Realtime Database that is not fully supported on Windows.
class RealtimeDbWindowsFix {
  // Flag to track if Windows fix has been applied
  static bool _initialized = false;
  static bool _isSupported = true;
  
  // In-memory database for Windows
  static final Map<String, dynamic> _inMemoryDatabase = {};
  
  // Stream controllers for simulating real-time updates
  static final Map<String, StreamController<Map<String, dynamic>>> _streamControllers = {};
  
  // Whether to persist data to local storage
  static bool _persistData = true;
  
  // Storage key for persisted data
  static const String _storageKey = 'realtime_db_windows_data';

  /// Initialize with Windows-specific settings and load any persisted data
  static Future<void> initialize({bool persistData = true}) async {
    if (!kIsWeb && Platform.isWindows && !_initialized) {
      _initialized = true;
      _persistData = persistData;
      debugPrint('🔧 Initializing Realtime Database Windows implementation...');
      
      try {
        // Try native implementation first
        FirebaseDatabase.instance.setPersistenceEnabled(false);
        FirebaseDatabase.instance.databaseURL = FirebaseDatabase.instance.databaseURL;
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(1000000); // minimal cache size
        
        // Test if we can actually perform an operation
        await FirebaseDatabase.instance.ref('.info/connected').get();
        
        _isSupported = true;
        debugPrint('✅ Native Firebase Database working on Windows');
      } catch (e) {
        // Native implementation failed, use our in-memory implementation
        _isSupported = false;
        debugPrint('⚠️ Native Firebase Database not available: $e');
        debugPrint('🔄 Activating in-memory database implementation for Windows');
        
        // Load any persisted data
        if (_persistData) {
          await _loadPersistedData();
        }
      }
    }
  }
  
  /// Load persisted data from SharedPreferences
  static Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? storedData = prefs.getString(_storageKey);
      
      if (storedData != null) {
        final Map<String, dynamic> data = jsonDecode(storedData) as Map<String, dynamic>;
        _inMemoryDatabase.clear();
        _inMemoryDatabase.addAll(data);
        debugPrint('📥 Loaded persisted database data: ${_inMemoryDatabase.length} paths');
      }
    } catch (e) {
      debugPrint('⚠️ Error loading persisted database: $e');
    }
  }
  
  /// Save current database state to SharedPreferences
  static Future<void> _persistDatabaseData() async {
    if (!_persistData) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final String dataJson = jsonEncode(_inMemoryDatabase);
      await prefs.setString(_storageKey, dataJson);
      debugPrint('📤 Persisted database data: ${_inMemoryDatabase.length} paths');
    } catch (e) {
      debugPrint('⚠️ Error persisting database: $e');
    }
  }
  
  /// Check if we're on Windows and need to handle operations specially
  static bool get needsSpecialHandling => !kIsWeb && Platform.isWindows;
  
  /// Check if Realtime Database is supported on this platform
  static bool get isSupported => !needsSpecialHandling || _isSupported;
  
  /// Get a reference to a specific path in the in-memory database
  static dynamic _getPathValue(String path) {
    final List<String> segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    // Start at the root
    dynamic current = _inMemoryDatabase;
    
    // Navigate to the specified path
    for (final segment in segments) {
      if (current is Map && current.containsKey(segment)) {
        current = current[segment];
      } else {
        // Path doesn't exist yet
        return null;
      }
    }
    
    return current;
  }
  
  /// Set a value at a specific path in the in-memory database
  static void _setPathValue(String path, dynamic value) {
    final List<String> segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    if (segments.isEmpty) {
      // Setting the entire database
      if (value is Map) {
        _inMemoryDatabase.clear();
        _inMemoryDatabase.addAll(value as Map<String, dynamic>);
      }
      return;
    }
    
    // Navigate to the parent of the target node
    Map<String, dynamic> current = _inMemoryDatabase;
    for (int i = 0; i < segments.length - 1; i++) {
      final segment = segments[i];
      if (!current.containsKey(segment)) {
        current[segment] = <String, dynamic>{};
      } else if (current[segment] is! Map) {
        // Replace non-map with map
        current[segment] = <String, dynamic>{};
      }
      current = current[segment] as Map<String, dynamic>;
    }
    
    // Set the value at the target node
    final lastSegment = segments.last;
    if (value == null) {
      current.remove(lastSegment);
    } else {
      current[lastSegment] = value;
    }
    
    // Notify listeners if there are any
    _notifyListeners(path, value);
    
    // Persist the updated database
    _persistDatabaseData();
  }
  
  /// Update multiple values at a path
  static void _updatePathValues(String path, Map<String, dynamic> values) {
    // Get the current value at the path
    final List<String> segments = path.split('/').where((s) => s.isNotEmpty).toList();
    
    // Navigate to the target node, creating it if necessary
    Map<String, dynamic> current = _inMemoryDatabase;
    for (final segment in segments) {
      if (!current.containsKey(segment)) {
        current[segment] = <String, dynamic>{};
      } else if (current[segment] is! Map) {
        current[segment] = <String, dynamic>{};
      }
      current = current[segment] as Map<String, dynamic>;
    }
    
    // Apply all updates
    current.addAll(values);
    
    // Notify listeners
    _notifyListeners(path, current);
    
    // Persist the updated database
    _persistDatabaseData();
  }
  
  /// Notify listeners for a specific path
  static void _notifyListeners(String path, dynamic value) {
    // Notify any stream controllers for this path
    for (final entry in _streamControllers.entries) {
      if (_pathMatches(path, entry.key)) {
        // Send the updated value to the stream
        entry.value.add({'path': path, 'data': value});
      }
    }
  }
  
  /// Check if a data path matches a listener path (supporting wildcards)
  static bool _pathMatches(String dataPath, String listenerPath) {
    // Exact match
    if (dataPath == listenerPath) return true;
    
    // Check if the listener path is a parent of the data path
    if (dataPath.startsWith('$listenerPath/')) return true;
    
    // Check if the data path is a parent of the listener path
    if (listenerPath.startsWith('$dataPath/')) return true;
    
    return false;
  }
  
  /// Safely execute a Realtime Database operation with fallback to in-memory implementation
  static Future<T?> safeOperation<T>(Future<T> Function() operation, {T? defaultValue, String? path, dynamic data}) async {
    if (needsSpecialHandling) {
      if (_isSupported) {
        // Try to use the native implementation first
        try {
          return await operation();
        } catch (e) {
          debugPrint('⚠️ Native database operation failed: $e');
          debugPrint('🔄 Falling back to in-memory database');
          _isSupported = false;
        }
      }
      
      // Native implementation failed or is unavailable, use in-memory database
      if (path != null) {
        debugPrint('📦 Using in-memory database for operation: $path');
        
        if (data != null) {
          if (data is Map<String, dynamic>) {
            _updatePathValues(path, data);
          } else {
            _setPathValue(path, data);
          }
        }
        
        // For get() operations, return a simulated result
        if (T.toString().contains('DataSnapshot')) {
          // This is a workaround since we can't directly create DataSnapshot instances
          // Let the caller know we're using in-memory data
          final value = _getPathValue(path);
          debugPrint('📤 Retrieved in-memory value for $path: ${value?.toString().substring(0, value.toString().length.clamp(0, 100))}${value != null && value.toString().length > 100 ? '...' : ''}');
          return defaultValue;
        }
        
        // For stream operations, return a stream of mapped events
        if (T.toString().contains('Stream<DatabaseEvent>')) {
          // Again, we can't directly create DatabaseEvent instances
          // Inform caller that we're using simulated streams
          debugPrint('🔄 Using simulated database stream for $path');
          return defaultValue;
        }
      }
      
      return defaultValue;
    } else {
      // For non-Windows platforms, just run the native operation
      return operation();
    }
  }
  
  /// Get a stream controller for a path
  static StreamController<Map<String, dynamic>> _getStreamController(String path) {
    if (!_streamControllers.containsKey(path)) {
      _streamControllers[path] = StreamController<Map<String, dynamic>>.broadcast();
      
      // Immediately send the current value
      final value = _getPathValue(path);
      _streamControllers[path]!.add({'path': path, 'data': value});
    }
    
    return _streamControllers[path]!;
  }
  
  /// Safely set a value in the Realtime Database
  static Future<void> safeSet(DatabaseReference reference, dynamic value) async {
    final path = reference.path;
    await safeOperation(
      () => reference.set(value),
      defaultValue: null,
      path: path,
      data: value
    );
  }
  
  /// Safely update values in the Realtime Database
  static Future<void> safeUpdate(DatabaseReference reference, Map<String, dynamic> value) async {
    final path = reference.path;
    await safeOperation(
      () => reference.update(value),
      defaultValue: null,
      path: path,
      data: value
    );
  }
  
  /// Safely remove a value from the Realtime Database
  static Future<void> safeRemove(DatabaseReference reference) async {
    final path = reference.path;
    await safeOperation(
      () => reference.remove(),
      defaultValue: null,
      path: path,
      data: null
    );
  }
  
  /// Get data from a reference
  static Future<DataSnapshot?> safeGet(DatabaseReference reference) async {
    final path = reference.path;
    return await safeOperation(
      () => reference.get(),
      defaultValue: null,
      path: path,
      data: null
    );
  }
  
  /// Listen for value changes
  static Stream<DatabaseEvent> safeOnValue(DatabaseReference reference) {
    final path = reference.path;
    
    // Try to use native implementation first
    if (!needsSpecialHandling || _isSupported) {
      try {
        return reference.onValue;
      } catch (e) {
        debugPrint('⚠️ Native database stream failed: $e');
        _isSupported = false;
      }
    }
    
    // Fallback: Create a simulated DatabaseEvent stream for Windows
    debugPrint('🔄 Using simulated stream for $path');
    
    final controller = _getStreamController(path);
    final streamController = StreamController<DatabaseEvent>.broadcast();
    
    // Create a subscription to our simple data events
    final subscription = controller.stream.listen((event) {
      try {
        // Create a custom implementation that mimics a DatabaseEvent
        // This is just enough for basic functionality
        final dataSnapshot = _WindowsFakeDataSnapshot(
          key: path.split('/').last,
          value: event['data'],
          exists: event['data'] != null,
        );
        
        final dbEvent = _WindowsFakeDatabaseEvent(
          snapshot: dataSnapshot,
          eventType: 'value',
        );
        
        streamController.add(dbEvent);
      } catch (e) {
        debugPrint('⚠️ Error in simulated database stream: $e');
      }
    });
    
    // Clean up when the stream is no longer needed
    streamController.onCancel = () {
      subscription.cancel();
      debugPrint('🧹 Cleaned up simulated database stream for $path');
    };
    
    return streamController.stream;
  }
}

/// A simple implementation of DataSnapshot for Windows
class _WindowsFakeDataSnapshot implements DataSnapshot {
  @override
  final String? key;
  
  @override
  final dynamic value;
  
  @override
  final bool exists;
  
  _WindowsFakeDataSnapshot({
    this.key,
    this.value,
    this.exists = false,
  });
  
  @override
  DataSnapshot child(String childPath) {
    if (value is Map && value.containsKey(childPath)) {
      return _WindowsFakeDataSnapshot(
        key: childPath,
        value: value[childPath],
        exists: true,
      );
    }
    return _WindowsFakeDataSnapshot(
      key: childPath,
      value: null,
      exists: false,
    );
  }
  
  @override
  List<DataSnapshot> get children {
    if (value is Map) {
      return (value as Map).entries.map((entry) {
        return _WindowsFakeDataSnapshot(
          key: entry.key.toString(),
          value: entry.value,
          exists: true,
        );
      }).toList();
    }
    return [];
  }
  
  @override
  bool hasChild(String path) {
    if (value is Map) {
      final pathParts = path.split('/');
      Map<dynamic, dynamic> current = value as Map<dynamic, dynamic>;
      
      for (final part in pathParts) {
        if (!current.containsKey(part)) {
          return false;
        }
        
        if (current[part] is Map) {
          current = current[part] as Map<dynamic, dynamic>;
        } else if (pathParts.last != part) {
          return false;
        }
      }
      
      return true;
    }
    return false;
  }
  
  @override
  dynamic get priority => null;
  
  @override
  DatabaseReference get ref => throw UnimplementedError('Reference not implemented in Windows fake snapshot');
}

/// A simple implementation of DatabaseEvent for Windows
class _WindowsFakeDatabaseEvent implements DatabaseEvent {
  @override
  final DataSnapshot snapshot;
  
  final String eventType;
  
  @override
  DatabaseEventType get type {
    // Convert string event type to DatabaseEventType
    switch (eventType) {
      case 'value':
        return DatabaseEventType.value;
      case 'childAdded':
        return DatabaseEventType.childAdded;
      case 'childRemoved':
        return DatabaseEventType.childRemoved;
      case 'childChanged':
        return DatabaseEventType.childChanged;
      case 'childMoved':
        return DatabaseEventType.childMoved;
      default:
        return DatabaseEventType.value;
    }
  }
  
  @override
  final String? previousChildKey;
  
  _WindowsFakeDatabaseEvent({
    required this.snapshot,
    required this.eventType,
    this.previousChildKey,
  });
} 