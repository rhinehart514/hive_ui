import 'package:flutter/foundation.dart';
import 'dart:async';
import 'analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'dart:collection';
import 'package:firebase_core/firebase_core.dart';

/// Provider for the performance service
final performanceServiceProvider = Provider<PerformanceService>((ref) {
  return PerformanceService(ref);
});

/// Service for monitoring app performance
class PerformanceService {
  final Ref _ref;
  final AnalyticsService _analytics = AnalyticsService();
  final Map<String, Stopwatch> _activeTraces = {};
  final Map<String, List<int>> _performanceData = {};
  
  // Firebase Performance Monitoring
  FirebasePerformance? _firebasePerformance;
  final Map<String, Trace> _firebaseTraces = {};
  
  // Frame timing monitoring
  final ValueNotifier<double> _frameRate = ValueNotifier<double>(60.0);
  int _frameCount = 0;
  DateTime _lastFrameTime = DateTime.now();
  Timer? _frameTimer;
  
  // Memory usage
  final ValueNotifier<int> _memoryUsage = ValueNotifier<int>(0);
  Timer? _memoryTimer;
  
  // Performance thresholds
  static const int _slowFrameThresholdMs = 16; // ~60fps
  
  // Cache for expensive operations
  final _computeCache = _LruCache<String, dynamic>(50);
  
  /// Get the current frame rate
  ValueNotifier<double> get frameRate => _frameRate;
  
  /// Get the current memory usage in MB
  ValueNotifier<int> get memoryUsage => _memoryUsage;

  /// Constructor
  PerformanceService(this._ref) {
    // Start monitoring frame rate in debug mode
    if (kDebugMode) {
      _startFrameMonitoring();
      _startMemoryMonitoring();
    }
    
    // Safe initialization of Firebase Performance
    _initializeFirebasePerformance();
  }
  
  /// Safely initialize Firebase Performance
  void _initializeFirebasePerformance() {
    if (kDebugMode) return; // No Firebase performance in debug mode
    
    try {
      if (Firebase.apps.isNotEmpty) {
        _firebasePerformance = FirebasePerformance.instance;
        _firebasePerformance?.setPerformanceCollectionEnabled(true);
        debugPrint('Firebase Performance initialized successfully');
      } else {
        debugPrint('Firebase not initialized yet, deferring Performance initialization');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Performance: $e');
    }
  }
  
  /// Start monitoring frame rate
  void _startFrameMonitoring() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameRendered());
    
    _frameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final timeDiff = now.difference(_lastFrameTime).inMilliseconds;
      
      if (timeDiff > 0) {
        final fps = 1000 * _frameCount / timeDiff;
        _frameRate.value = fps;
        
        if (kDebugMode && fps < 40) {
          debugPrint('⚠️ Low frame rate detected: ${fps.toStringAsFixed(1)} FPS');
        }
        
        _frameCount = 0;
        _lastFrameTime = now;
      }
    });
  }
  
  void _onFrameRendered() {
    _frameCount++;
    WidgetsBinding.instance.addPostFrameCallback((_) => _onFrameRendered());
  }
  
  /// Start monitoring memory usage
  void _startMemoryMonitoring() {
    _memoryTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        // This is a simplistic approach - in a real app you'd use platform channels
        // to get accurate memory info from the OS
        final memInfo = await _getMemoryInfo();
        _memoryUsage.value = memInfo;
        
        if (kDebugMode && memInfo > 200) {
          debugPrint('⚠️ High memory usage: $memInfo MB');
        }
      } catch (e) {
        // Ignore memory monitoring errors
      }
    });
  }
  
  Future<int> _getMemoryInfo() async {
    // This is a very approximate measurement
    // A real implementation would use platform channels to get OS memory info
    return 0; // Placeholder return 
  }

  /// Start tracking a performance operation
  void startTrace(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTraces[operationName] = stopwatch;
    
    // Start Firebase trace in non-debug mode
    if (!kDebugMode) {
      try {
        // Try to initialize Firebase Performance if it wasn't available at construction time
        if (_firebasePerformance == null && Firebase.apps.isNotEmpty) {
          _initializeFirebasePerformance();
        }
        
        if (_firebasePerformance != null) {
          final trace = _firebasePerformance!.newTrace(operationName);
          _firebaseTraces[operationName] = trace;
          trace.start();
        }
      } catch (e) {
        // Ignore Firebase errors in production
        debugPrint('Error starting Firebase trace: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('⏱️ Started trace: $operationName');
    }
  }

  /// Stop tracking a performance operation and record results
  void stopTrace(String operationName) {
    final stopwatch = _activeTraces.remove(operationName);

    if (stopwatch == null) {
      if (kDebugMode) {
        debugPrint('⚠️ Attempted to stop non-existent trace: $operationName');
      }
      return;
    }

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;
    
    // Stop Firebase trace if it exists
    if (!kDebugMode) {
      try {
        final trace = _firebaseTraces.remove(operationName);
        if (trace != null) {
          trace.stop();
        }
      } catch (e) {
        // Ignore Firebase errors in production
      }
    }

    // Store performance data
    if (!_performanceData.containsKey(operationName)) {
      _performanceData[operationName] = [];
    }
    _performanceData[operationName]!.add(durationMs);

    // Trim old performance data if necessary
    if (_performanceData[operationName]!.length > 100) {
      _performanceData[operationName]!.removeAt(0);
    }

    // Log to analytics
    _analytics.trackPerformance(operationName, durationMs);

    if (kDebugMode) {
      debugPrint('⏱️ Completed trace: $operationName in ${durationMs}ms');
      
      // Flag slow operations in debug mode
      if (durationMs > 100) {
        debugPrint('⚠️ Slow operation detected: $operationName took ${durationMs}ms');
      }
    }
  }

  /// Track an asynchronous operation
  Future<T> trackAsync<T>(
      String operationName, Future<T> Function() operation) async {
    startTrace(operationName);
    try {
      return await operation();
    } finally {
      stopTrace(operationName);
    }
  }

  /// Track a synchronous operation
  T trackSync<T>(String operationName, T Function() operation) {
    startTrace(operationName);
    try {
      return operation();
    } finally {
      stopTrace(operationName);
    }
  }
  
  /// Cache the result of an expensive computation
  T cachedCompute<T>(String cacheKey, T Function() computation) {
    // Check cache first
    if (_computeCache.containsKey(cacheKey)) {
      return _computeCache.get(cacheKey) as T;
    }
    
    // Perform the computation and cache it
    final result = computation();
    _computeCache.put(cacheKey, result);
    return result;
  }
  
  /// Compute something expensive on a background isolate with caching
  Future<T> backgroundCompute<T>(
    String cacheKey,
    T Function(dynamic) computation,
    dynamic message,
  ) async {
    // Check cache first
    if (_computeCache.containsKey(cacheKey)) {
      return _computeCache.get(cacheKey) as T;
    }
    
    // Compute in background
    final result = await compute(computation, message);
    _computeCache.put(cacheKey, result);
    return result;
  }

  /// Mark a significant event for performance tracking
  void markEvent(String eventName) {
    if (kDebugMode) {
      debugPrint('⏱️ Performance event: $eventName at ${DateTime.now()}');
    }

    _analytics.trackEvent('performance_event', {
      'event_name': eventName,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Add custom metric to Firebase trace if one is active
    if (!kDebugMode) {
      try {
        if (_firebaseTraces.isNotEmpty) {
          final trace = _firebaseTraces.values.first;
          trace.incrementMetric('event_$eventName', 1);
        }
      } catch (e) {
        // Ignore Firebase errors
      }
    }
  }

  /// Get performance statistics for an operation
  Map<String, dynamic> getOperationStats(String operationName) {
    final measurements = _performanceData[operationName];

    if (measurements == null || measurements.isEmpty) {
      return {
        'name': operationName,
        'count': 0,
        'average': 0,
        'min': 0,
        'max': 0,
      };
    }

    final count = measurements.length;
    final sum = measurements.reduce((a, b) => a + b);
    final average = sum / count;
    final min = measurements.reduce((a, b) => a < b ? a : b);
    final max = measurements.reduce((a, b) => a > b ? a : b);

    return {
      'name': operationName,
      'count': count,
      'average': average.toStringAsFixed(2),
      'min': min,
      'max': max,
    };
  }

  /// Get performance statistics for all tracked operations
  Map<String, Map<String, dynamic>> getAllStats() {
    final Map<String, Map<String, dynamic>> stats = {};

    for (final operation in _performanceData.keys) {
      stats[operation] = getOperationStats(operation);
    }

    return stats;
  }

  /// Create a widget that tracks build performance
  Widget trackBuildPerformance(
      String widgetName, Widget Function(BuildContext) builder) {
    return _PerformanceTrackingWidget(
      widgetName: widgetName,
      performanceService: this,
      builder: builder,
    );
  }
  
  /// Clear all performance data
  void clearData() {
    _performanceData.clear();
    _activeTraces.clear();
    _firebaseTraces.clear();
    _computeCache.clear();
  }
  
  /// Dispose timers and resources
  void dispose() {
    _frameTimer?.cancel();
    _memoryTimer?.cancel();
    
    // Stop all active traces
    for (final operationName in _activeTraces.keys.toList()) {
      stopTrace(operationName);
    }
    
    // Clear caches
    clearData();
  }
  
  /// Record image load time for performance tracking
  void recordImageLoadTime(String imageUrl, int loadTimeMs) {
    // Track as a performance metric
    if (!_performanceData.containsKey('image_load')) {
      _performanceData['image_load'] = [];
    }
    _performanceData['image_load']!.add(loadTimeMs);
    
    // Log slow image loads
    if (kDebugMode && loadTimeMs > 500) {
      debugPrint('⚠️ Slow image load: $imageUrl took ${loadTimeMs}ms');
    }
    
    // Log to analytics for images that take too long
    if (loadTimeMs > 1000) {
      _analytics.trackEvent('slow_image_load', {
        'image_url': imageUrl,
        'load_time_ms': loadTimeMs,
      });
    }
  }
  
  /// Record image load failure for analytics
  void recordImageLoadFailure(String imageUrl) {
    // Log to analytics
    _analytics.trackEvent('image_load_failure', {
      'image_url': imageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    if (kDebugMode) {
      debugPrint('❌ Image load failed: $imageUrl');
    }
  }
}

/// Widget that tracks build performance
class _PerformanceTrackingWidget extends StatelessWidget {
  final String widgetName;
  final PerformanceService performanceService;
  final Widget Function(BuildContext) builder;

  const _PerformanceTrackingWidget({
    required this.widgetName,
    required this.performanceService,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return performanceService.trackSync<Widget>(
      'build_$widgetName',
      () => builder(context),
    );
  }
}

/// Extension to trace performance on Future operations
extension PerformanceTrackingFutureExtension<T> on Future<T> {
  /// Track this future's performance
  Future<T> tracked(String operationName, PerformanceService service) {
    service.startTrace(operationName);
    return then((value) {
      service.stopTrace(operationName);
      return value;
    }).catchError((error) {
      service.stopTrace(operationName);
      throw error;
    });
  }
}

/// Extension to measure build performance
extension PerformanceWidgetExtension on Widget {
  /// Wrap this widget with performance tracking
  Widget measureBuildPerformance(String widgetName, WidgetRef ref) {
    final performanceService = ref.read(performanceServiceProvider);
    return performanceService.trackBuildPerformance(
      widgetName,
      (_) => this,
    );
  }
}

/// LRU Cache implementation for expensive computations
class _LruCache<K, V> {
  final int _maxSize;
  final LinkedHashMap<K, V> _cache = LinkedHashMap<K, V>();
  
  _LruCache(this._maxSize);
  
  V? get(K key) {
    if (!_cache.containsKey(key)) {
      return null;
    }
    
    // Move to the end (most recently used)
    final value = _cache.remove(key);
    _cache[key] = value as V;
    return value;
  }
  
  void put(K key, V value) {
    if (_cache.containsKey(key)) {
      _cache.remove(key);
    } else if (_cache.length >= _maxSize) {
      // Remove the first item (least recently used)
      _cache.remove(_cache.keys.first);
    }
    
    _cache[key] = value;
  }
  
  bool containsKey(K key) {
    return _cache.containsKey(key);
  }
  
  void clear() {
    _cache.clear();
  }
}
