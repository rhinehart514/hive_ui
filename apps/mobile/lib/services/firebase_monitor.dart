import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_ui/services/request_interceptor.dart';

/// Monitor Firebase usage to track read operations and costs
class FirebaseMonitor {
  // Read operation counter and stats
  static int _readOperations = 0;
  static int _cachedOperations = 0;
  static int _sessionStartTime = 0;
  static int _sessionsTracked = 0;
  static double _estimatedCost = 0.0;

  // Cost constants - 0.06 USD per 100,000 reads
  static const double _readCostPer100k = 0.06;

  // Persistent storage keys
  static const String _readOpsKey = 'firebase_read_ops';
  static const String _cachedOpsKey = 'firebase_cached_ops';
  static const String _sessionsKey = 'firebase_sessions';
  static const String _costKey = 'firebase_estimated_cost';

  // Timer for periodic reporting
  static Timer? _reportingTimer;
  static bool _isMonitoring = false;

  /// Start monitoring Firebase usage
  static Future<void> startMonitoring() async {
    if (_isMonitoring) return;

    _isMonitoring = true;
    _sessionStartTime = DateTime.now().millisecondsSinceEpoch;

    // Load previous stats
    await _loadStats();

    // Increment session count
    _sessionsTracked++;

    // Start periodic reporting
    _reportingTimer =
        Timer.periodic(const Duration(minutes: 5), (_) => _reportUsage());

    debugPrint('📊 Firebase monitoring started');
  }

  /// Record a read operation
  static void recordRead({int count = 1, bool cached = false}) {
    if (!_isMonitoring) return;

    if (cached) {
      _cachedOperations += count;
    } else {
      _readOperations += count;
      // Update estimated cost
      _estimatedCost += (count / 100000) * _readCostPer100k;
    }
  }

  /// Get current usage statistics
  static Map<String, dynamic> getStats() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final sessionDuration = (now - _sessionStartTime) / 1000; // in seconds

    final stats = {
      'readOperations': _readOperations,
      'cachedOperations': _cachedOperations,
      'totalOperations': _readOperations + _cachedOperations,
      'cacheSavingsPercent': _readOperations > 0
          ? (_cachedOperations / (_readOperations + _cachedOperations) * 100)
              .toStringAsFixed(1)
          : '0.0',
      'estimatedCost': '\$${_estimatedCost.toStringAsFixed(5)}',
      'sessionsTracked': _sessionsTracked,
      'sessionDuration': '${(sessionDuration / 60).toStringAsFixed(1)} minutes',
      'readsPerMinute': sessionDuration > 0
          ? (_readOperations / (sessionDuration / 60)).toStringAsFixed(1)
          : '0.0',
    };

    // Add request interceptor stats if available
    try {
      final interceptorStats = RequestInterceptor.getStats();
      stats['requestsIntercepted'] =
          interceptorStats['interceptedRequests'] ?? 0;
      stats['totalRequests'] = interceptorStats['totalRequests'] ?? 0;
      stats['savedRequests'] = interceptorStats['savedRequests'] ?? 0;
    } catch (e) {
      // Ignore if not available
    }

    return stats;
  }

  /// Report current usage to debug console
  static void _reportUsage() {
    if (!_isMonitoring) return;

    final stats = getStats();

    debugPrint('\n📊 FIREBASE USAGE REPORT:');
    debugPrint('Read operations: ${stats['readOperations']}');
    debugPrint('Cached operations: ${stats['cachedOperations']}');
    debugPrint('Cache savings: ${stats['cacheSavingsPercent']}%');
    debugPrint('Est. cost: ${stats['estimatedCost']}');
    debugPrint('Reads per minute: ${stats['readsPerMinute']}');

    // Save stats
    _saveStats();
  }

  /// Stop monitoring and save stats
  static Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    // Cancel timer
    _reportingTimer?.cancel();
    _reportingTimer = null;

    // Report final usage
    _reportUsage();

    // Save stats
    await _saveStats();

    _isMonitoring = false;
    debugPrint('Firebase monitoring stopped');
  }

  /// Reset monitoring stats
  static Future<void> resetStats() async {
    _readOperations = 0;
    _cachedOperations = 0;
    _estimatedCost = 0.0;

    // Don't reset session count

    // Clear stored stats
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_readOpsKey);
    await prefs.remove(_cachedOpsKey);
    await prefs.remove(_costKey);

    debugPrint('Firebase monitoring stats reset');
  }

  /// Save stats to persistent storage
  static Future<void> _saveStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_readOpsKey, _readOperations);
      await prefs.setInt(_cachedOpsKey, _cachedOperations);
      await prefs.setInt(_sessionsKey, _sessionsTracked);
      await prefs.setDouble(_costKey, _estimatedCost);
    } catch (e) {
      debugPrint('Error saving Firebase stats: $e');
    }
  }

  /// Load stats from persistent storage
  static Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _readOperations = prefs.getInt(_readOpsKey) ?? 0;
      _cachedOperations = prefs.getInt(_cachedOpsKey) ?? 0;
      _sessionsTracked = prefs.getInt(_sessionsKey) ?? 0;
      _estimatedCost = prefs.getDouble(_costKey) ?? 0.0;
    } catch (e) {
      debugPrint('Error loading Firebase stats: $e');
    }
  }
}
