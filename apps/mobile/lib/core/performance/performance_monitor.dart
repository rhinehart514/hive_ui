import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A lightweight performance monitoring utility for tracking critical paths
class PerformanceMonitor {
  static const String _storageKey = 'performance_metrics';
  static final Map<String, Stopwatch> _activeTraces = {};
  static final Map<String, List<int>> _metricsCache = {};
  
  /// Start tracking a performance trace
  static void startTrace(String traceName) {
    if (_activeTraces.containsKey(traceName)) {
      // Reset if already started
      _activeTraces[traceName]!.reset();
      _activeTraces[traceName]!.start();
    } else {
      final stopwatch = Stopwatch()..start();
      _activeTraces[traceName] = stopwatch;
    }
  }
  
  /// Stop tracking a performance trace and record the result
  static Future<int> stopTrace(String traceName) async {
    if (!_activeTraces.containsKey(traceName)) {
      return 0; // Not started
    }
    
    final stopwatch = _activeTraces[traceName]!;
    stopwatch.stop();
    final elapsedMs = stopwatch.elapsedMilliseconds;
    
    await _recordMetric(traceName, elapsedMs);
    
    return elapsedMs;
  }
  
  /// Record a performance metric
  static Future<void> _recordMetric(String name, int valueMs) async {
    // Keep in-memory cache of recent metrics
    if (!_metricsCache.containsKey(name)) {
      _metricsCache[name] = [];
    }
    
    _metricsCache[name]!.add(valueMs);
    
    // Only keep the last 100 values
    if (_metricsCache[name]!.length > 100) {
      _metricsCache[name]!.removeAt(0);
    }
    
    // Periodically save to disk (not on every call)
    if (_metricsCache[name]!.length % 10 == 0) {
      await _persistMetrics();
    }
  }
  
  /// Save metrics to persistent storage
  static Future<void> _persistMetrics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, json.encode(_metricsCache));
    } catch (e) {
      // Silently fail for non-critical performance tracking
    }
  }
  
  /// Calculate P95 (95th percentile) for a metric
  static Future<double> getP95(String metricName) async {
    final metrics = await _getMetrics(metricName);
    if (metrics.isEmpty) return 0;
    
    // Sort metrics to calculate percentile
    metrics.sort();
    
    // Calculate the 95th percentile index
    final idx = (metrics.length * 0.95).floor();
    return metrics[idx].toDouble();
  }
  
  /// Calculate average for a metric
  static Future<double> getAverage(String metricName) async {
    final metrics = await _getMetrics(metricName);
    if (metrics.isEmpty) return 0;
    
    final sum = metrics.fold<int>(0, (prev, curr) => prev + curr);
    return sum / metrics.length;
  }
  
  /// Get cached metrics for a given name
  static Future<List<int>> _getMetrics(String metricName) async {
    // Check in-memory cache first
    if (_metricsCache.containsKey(metricName)) {
      return List<int>.from(_metricsCache[metricName]!);
    }
    
    // Load from storage if not in memory
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? metricsJson = prefs.getString(_storageKey);
      
      if (metricsJson != null) {
        final Map<String, dynamic> allMetrics = 
            json.decode(metricsJson) as Map<String, dynamic>;
        
        if (allMetrics.containsKey(metricName)) {
          final List<dynamic> rawMetrics = allMetrics[metricName] as List<dynamic>;
          return rawMetrics.map((m) => m as int).toList();
        }
      }
    } catch (e) {
      // Silently fail for non-critical performance tracking
    }
    
    return [];
  }
  
  /// Clear all stored metrics
  static Future<void> clearMetrics() async {
    _metricsCache.clear();
    _activeTraces.clear();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      // Silently fail for non-critical performance tracking
    }
  }
  
  /// Check if a metric exceeds the threshold for P95
  static Future<bool> isP95ThresholdExceeded(
      String metricName, int thresholdMs) async {
    final p95 = await getP95(metricName);
    return p95 > thresholdMs;
  }
  
  /// Check if time-to-feed performance meets the requirement of < 20s (P95)
  static Future<bool> isTimeToFeedAcceptable() async {
    const int timeToFeedThresholdMs = 20000; // 20 seconds
    return !(await isP95ThresholdExceeded('time_to_feed', timeToFeedThresholdMs));
  }
  
  /// Predefined trace: Measure time to load feed
  static void startTimeToFeedTrace() {
    startTrace('time_to_feed');
  }
  
  /// Stop time to feed trace
  static Future<int> stopTimeToFeedTrace() async {
    return await stopTrace('time_to_feed');
  }
  
  /// Predefined trace: Measure magic link delivery time
  static void startMagicLinkDeliveryTrace() {
    startTrace('magic_link_delivery');
  }
  
  /// Stop magic link delivery trace
  static Future<int> stopMagicLinkDeliveryTrace() async {
    return await stopTrace('magic_link_delivery');
  }
  
  /// Predefined trace: Measure onboarding completion time
  static void startOnboardingCompletionTrace() {
    startTrace('onboarding_completion');
  }
  
  /// Stop onboarding completion trace
  static Future<int> stopOnboardingCompletionTrace() async {
    return await stopTrace('onboarding_completion');
  }
} 