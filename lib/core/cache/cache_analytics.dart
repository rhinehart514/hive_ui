import 'package:flutter/foundation.dart';

/// Tracks cache performance and usage statistics
class CacheAnalytics {
  // Cache hit/miss tracking
  int _hits = 0;
  int _misses = 0;
  
  // Cache operation counts
  int _puts = 0;
  int _gets = 0;
  int _invalidations = 0;
  int _evictions = 0;
  
  // Timing metrics
  final Map<String, List<Duration>> _accessTimes = {};
  
  // Cache utilization
  final Map<String, int> _cacheKeyAccesses = {};
  final Map<String, int> _cacheKeyHits = {};
  
  // Record a cache hit
  void recordHit(String cacheKey) {
    _hits++;
    _gets++;
    _cacheKeyAccesses[cacheKey] = (_cacheKeyAccesses[cacheKey] ?? 0) + 1;
    _cacheKeyHits[cacheKey] = (_cacheKeyHits[cacheKey] ?? 0) + 1;
  }
  
  // Record a cache miss
  void recordMiss(String cacheKey) {
    _misses++;
    _gets++;
    _cacheKeyAccesses[cacheKey] = (_cacheKeyAccesses[cacheKey] ?? 0) + 1;
  }
  
  // Record a new cache entry
  void recordPut(String cacheKey) {
    _puts++;
  }
  
  // Record a cache entry invalidation
  void recordInvalidation(String cacheKey) {
    _invalidations++;
  }
  
  // Record a cache eviction (removal due to size constraints, etc.)
  void recordEviction(String cacheKey) {
    _evictions++;
  }
  
  // Record operation execution time
  void recordAccessTime(String cacheKey, Duration accessTime) {
    if (!_accessTimes.containsKey(cacheKey)) {
      _accessTimes[cacheKey] = [];
    }
    _accessTimes[cacheKey]!.add(accessTime);
    
    // Trim list to avoid excessive memory usage
    if (_accessTimes[cacheKey]!.length > 100) {
      _accessTimes[cacheKey] = _accessTimes[cacheKey]!.sublist(50);
    }
  }
  
  // Get the hit rate (percentage of cache hits)
  double get hitRate {
    if (_gets == 0) return 0.0;
    return _hits / _gets;
  }
  
  // Get hit rate formatted as a percentage
  String get hitRatePercentage {
    return '${(hitRate * 100).toStringAsFixed(1)}%';
  }
  
  // Get average access time for a cache key
  Duration? getAverageAccessTime(String cacheKey) {
    final times = _accessTimes[cacheKey];
    if (times == null || times.isEmpty) return null;
    
    final totalMicroseconds = times.fold<int>(
      0, (sum, duration) => sum + duration.inMicroseconds
    );
    
    return Duration(microseconds: totalMicroseconds ~/ times.length);
  }
  
  // Get the most accessed cache keys
  List<MapEntry<String, int>> getTopAccessedKeys({int limit = 10}) {
    final sortedEntries = _cacheKeyAccesses.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEntries.take(limit).toList();
  }
  
  // Get the least effective cache keys (high accesses, low hit rate)
  List<MapEntry<String, double>> getLeastEffectiveKeys({int limit = 10}) {
    final hitRates = <String, double>{};
    
    for (final key in _cacheKeyAccesses.keys) {
      final accesses = _cacheKeyAccesses[key] ?? 0;
      final hits = _cacheKeyHits[key] ?? 0;
      
      if (accesses > 10) { // Only consider keys with significant access
        hitRates[key] = hits / accesses;
      }
    }
    
    final sortedEntries = hitRates.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sortedEntries.take(limit).toList();
  }
  
  // Reset all statistics
  void reset() {
    _hits = 0;
    _misses = 0;
    _puts = 0;
    _gets = 0;
    _invalidations = 0;
    _evictions = 0;
    _accessTimes.clear();
    _cacheKeyAccesses.clear();
    _cacheKeyHits.clear();
    
    debugPrint('CacheAnalytics: Statistics reset');
  }
  
  // Get a summary of cache statistics
  Map<String, dynamic> getSummary() {
    return {
      'hits': _hits,
      'misses': _misses,
      'puts': _puts,
      'gets': _gets,
      'invalidations': _invalidations,
      'evictions': _evictions,
      'hitRate': hitRate,
      'hitRatePercentage': hitRatePercentage,
      'uniqueKeys': _cacheKeyAccesses.length,
      'topAccessedKeys': getTopAccessedKeys(limit: 5)
          .map((e) => {'key': e.key, 'accesses': e.value})
          .toList(),
      'leastEffectiveKeys': getLeastEffectiveKeys(limit: 5)
          .map((e) => {'key': e.key, 'hitRate': '${(e.value * 100).toStringAsFixed(1)}%'})
          .toList(),
    };
  }
  
  // Log a summary of cache statistics
  void logSummary() {
    final summary = getSummary();
    
    debugPrint('📊 CACHE ANALYTICS SUMMARY');
    debugPrint('Hit rate: ${summary['hitRatePercentage']} (${summary['hits']} hits, ${summary['misses']} misses)');
    debugPrint('Operations: ${summary['gets']} gets, ${summary['puts']} puts, ${summary['invalidations']} invalidations, ${summary['evictions']} evictions');
    debugPrint('Unique keys: ${summary['uniqueKeys']}');
    
    debugPrint('Top accessed keys:');
    for (final key in summary['topAccessedKeys']) {
      debugPrint('  ${key['key']}: ${key['accesses']} accesses');
    }
    
    debugPrint('Least effective keys:');
    for (final key in summary['leastEffectiveKeys']) {
      debugPrint('  ${key['key']}: ${key['hitRate']} hit rate');
    }
  }
} 