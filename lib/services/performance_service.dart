import 'package:flutter/foundation.dart';
import 'dart:async';
import 'analytics_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// Constructor
  PerformanceService(this._ref);

  /// Start tracking a performance operation
  void startTrace(String operationName) {
    final stopwatch = Stopwatch()..start();
    _activeTraces[operationName] = stopwatch;

    if (kDebugMode) {
      print('⏱️ Started trace: $operationName');
    }
  }

  /// Stop tracking a performance operation and record results
  void stopTrace(String operationName) {
    final stopwatch = _activeTraces.remove(operationName);

    if (stopwatch == null) {
      if (kDebugMode) {
        print('⚠️ Attempted to stop non-existent trace: $operationName');
      }
      return;
    }

    stopwatch.stop();
    final durationMs = stopwatch.elapsedMilliseconds;

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
      print('⏱️ Completed trace: $operationName in ${durationMs}ms');
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

  /// Mark a significant event for performance tracking
  void markEvent(String eventName) {
    if (kDebugMode) {
      print('⏱️ Performance event: $eventName at ${DateTime.now()}');
    }

    _analytics.trackEvent('performance_event', {
      'event_name': eventName,
      'timestamp': DateTime.now().toIso8601String(),
    });
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
