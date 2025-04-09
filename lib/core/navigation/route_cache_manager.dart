import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:collection';
import 'package:hive_ui/core/navigation/route_cache_ttl.dart';

/// Defines cache lifetime for different route types
class RouteCacheTTL {
  /// Default cache lifetime
  static const Duration defaultTTL = Duration(minutes: 5);
  
  /// Cache lifetime for home/feed routes
  static const Duration feedRoute = Duration(minutes: 3);
  
  /// Cache lifetime for profile routes
  static const Duration profileRoute = Duration(minutes: 10);
  
  /// Cache lifetime for event routes
  static const Duration eventRoute = Duration(minutes: 5);
  
  /// Cache lifetime for space routes
  static const Duration spaceRoute = Duration(minutes: 8);
  
  /// Cache lifetime for organization routes
  static const Duration organizationRoute = Duration(minutes: 8);
  
  /// Cache lifetime for settings routes
  static const Duration settingsRoute = Duration(minutes: 15);
  
  /// Get TTL based on route path
  static Duration getTTLForRoute(String path) {
    if (path.startsWith('/home')) {
      return feedRoute;
    } else if (path.startsWith('/profile')) {
      return profileRoute;
    } else if (path.contains('/event/')) {
      return eventRoute;
    } else if (path.startsWith('/spaces')) {
      return spaceRoute;
    } else if (path.contains('/organizations')) {
      return organizationRoute;
    } else if (path.startsWith('/settings')) {
      return settingsRoute;
    }
    return defaultTTL;
  }
}

/// Manages a cache of route data with TTL (time-to-live) support
/// 
/// This class implements an LRU (Least Recently Used) cache for route data
/// with configurable expiration times for different route types.
class RouteCacheManager {
  /// Maximum number of routes to keep in cache
  static const int _maxCacheSize = 20;
  
  /// Internal cache storage with LinkedHashMap for LRU ordering
  final Map<String, _CacheEntry> _cache = LinkedHashMap<String, _CacheEntry>();
  
  /// Map of cached routes with their expiration time (for page caching)
  final Map<String, _CachedRoute> _pageCache = {};
  
  /// Queue for managing page cache eviction (LRU)
  final ListQueue<String> _pageCacheQueue = ListQueue<String>();
  
  /// Constructor
  RouteCacheManager();
  
  /// Stores route data in the cache with the specified key and TTL
  /// 
  /// If the cache exceeds [_maxCacheSize], the least recently used entry will be removed.
  void cacheRoute<T>({
    required String cacheKey,
    required T data,
    Duration? ttl,
  }) {
    // If cache is at capacity, remove least recently used item (first in LinkedHashMap)
    if (_cache.length >= _maxCacheSize && !_cache.containsKey(cacheKey)) {
      _cache.remove(_cache.keys.first);
    }
    
    // Calculate expiration time
    final expirationTime = ttl != null && ttl != Duration.zero
        ? DateTime.now().add(ttl)
        : null;
    
    // Store the data with expiration time
    _cache[cacheKey] = _CacheEntry<T>(
      data: data,
      expirationTime: expirationTime,
      cachedAt: DateTime.now(),
    );
  }
  
  /// Retrieves cached route data if it exists and hasn't expired
  /// 
  /// Returns null if the data doesn't exist or has expired
  T? getRouteData<T>(String cacheKey) {
    final entry = _cache[cacheKey];
    
    // Return null if no entry exists
    if (entry == null) {
      return null;
    }
    
    // Check if entry has expired
    if (entry.expirationTime != null && 
        DateTime.now().isAfter(entry.expirationTime!)) {
      // Remove expired entry
      _cache.remove(cacheKey);
      return null;
    }
    
    // Move this entry to the end of the LinkedHashMap (mark as recently used)
    final data = entry.data;
    _cache.remove(cacheKey);
    _cache[cacheKey] = entry;
    
    return data as T;
  }
  
  /// Check if a route page is cached
  bool isCached(String path) {
    if (!_pageCache.containsKey(path)) {
      return false;
    }
    
    final cachedRoute = _pageCache[path]!;
    if (cachedRoute.isExpired()) {
      _removeFromPageCache(path);
      return false;
    }
    
    return true;
  }
  
  /// Get a cached route page
  Page<dynamic>? getCachedRoute(String path) {
    if (!isCached(path)) {
      return null;
    }
    
    // Update position in LRU queue
    _pageCacheQueue.remove(path);
    _pageCacheQueue.addLast(path);
    
    return _pageCache[path]!.page;
  }
  
  /// Add a route page to the cache
  void cacheRoutePage(String path, Page<dynamic> page, {Duration? ttl}) {
    if (_pageCacheQueue.length >= _maxCacheSize && !_pageCacheQueue.contains(path)) {
      _evictLeastRecentlyUsed();
    }
    
    // Get appropriate TTL
    final cacheTTL = ttl ?? RouteCacheTTL.getTTLForRoute(path);
    
    // Cache the route
    _pageCache[path] = _CachedRoute(
      page: page,
      expiresAt: DateTime.now().add(cacheTTL),
    );
    
    // Update LRU queue
    if (_pageCacheQueue.contains(path)) {
      _pageCacheQueue.remove(path);
    }
    _pageCacheQueue.addLast(path);
    
    debugPrint('🎯 RouteCacheManager: Cached route for "$path" with TTL: ${cacheTTL.inMinutes}m');
  }
  
  /// Invalidate a specific route in the cache
  void invalidateRoute(String cacheKey) {
    _cache.remove(cacheKey);
    _removeFromPageCache(cacheKey);
  }
  
  /// Invalidate all routes that match the given pattern
  void invalidateRoutesByPattern(String pattern) {
    // Clear data cache entries
    final keysToRemove = _cache.keys
        .where((key) => key.contains(pattern))
        .toList();
    
    for (final key in keysToRemove) {
      _cache.remove(key);
    }
    
    // Clear page cache entries
    final routesToRemove = _pageCache.keys
        .where((path) => path.contains(pattern))
        .toList();
    
    for (final path in routesToRemove) {
      _removeFromPageCache(path);
    }
    
    debugPrint('🧹 RouteCacheManager: Invalidated routes matching "$pattern"');
  }
  
  /// Clear the entire cache (both data and pages)
  void clearCache() {
    _cache.clear();
    _pageCache.clear();
    _pageCacheQueue.clear();
    debugPrint('🧹 RouteCacheManager: Cleared entire route cache');
  }
  
  /// Check for and clean expired cache entries
  void cleanExpiredCaches() {
    final now = DateTime.now();
    
    // Clean data cache
    final expiredDataKeys = _cache.entries
        .where((entry) => entry.value.expirationTime != null && 
                          entry.value.expirationTime!.isBefore(now))
        .map((entry) => entry.key)
        .toList();
    
    for (final key in expiredDataKeys) {
      _cache.remove(key);
    }
    
    // Clean page cache
    final expiredRoutes = _pageCache.entries
        .where((entry) => entry.value.expiresAt.isBefore(now))
        .map((entry) => entry.key)
        .toList();
    
    for (final path in expiredRoutes) {
      _removeFromPageCache(path);
    }
    
    final totalRemoved = expiredDataKeys.length + expiredRoutes.length;
    if (totalRemoved > 0) {
      debugPrint('🧹 RouteCacheManager: Cleaned $totalRemoved expired cache entries');
    }
  }
  
  /// Remove a route from page cache
  void _removeFromPageCache(String path) {
    _pageCache.remove(path);
    _pageCacheQueue.remove(path);
  }
  
  /// Evict least recently used route from page cache
  void _evictLeastRecentlyUsed() {
    if (_pageCacheQueue.isEmpty) return;
    
    final oldestPath = _pageCacheQueue.removeFirst();
    _pageCache.remove(oldestPath);
    debugPrint('🧹 RouteCacheManager: Evicted LRU route: "$oldestPath"');
  }
  
  /// Returns the number of items currently in the cache
  int get cacheSize => _cache.length + _pageCache.length;
  
  /// Returns all cache keys for debugging purposes
  List<String> get allCacheKeys => [..._cache.keys, ..._pageCache.keys];
  
  /// Gets cache statistics for debugging and monitoring
  Map<String, dynamic> getCacheStats() {
    final now = DateTime.now();
    return {
      'dataCache': {
        'size': _cache.length,
        'keys': _cache.keys.toList(),
        'ages': _cache.map((key, entry) => 
            MapEntry(key, now.difference(entry.cachedAt).inSeconds)),
        'expirationTimes': _cache.map((key, entry) => 
            MapEntry(key, entry.expirationTime)),
      },
      'pageCache': {
        'size': _pageCache.length,
        'keys': _pageCache.keys.toList(),
        'routes': _pageCache.entries.map((entry) {
          final timeLeft = entry.value.expiresAt.difference(now);
          return {
            'path': entry.key,
            'expires_in_seconds': timeLeft.inSeconds,
            'is_expired': timeLeft.isNegative,
          };
        }).toList(),
      },
      'totalCacheSize': cacheSize,
      'maxCacheSize': _maxCacheSize,
      'cacheUsagePercent': (_cache.length + _pageCache.length) / (_maxCacheSize * 2) * 100,
    };
  }
}

/// Class representing a cached route page
class _CachedRoute {
  /// The cached page
  final Page<dynamic> page;
  
  /// When this cache entry expires
  final DateTime expiresAt;
  
  /// Constructor
  _CachedRoute({
    required this.page,
    required this.expiresAt,
  });
  
  /// Check if this cache entry is expired
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }
}

/// Internal class representing a cache entry with expiration information
class _CacheEntry<T> {
  /// The cached data
  final T data;
  
  /// Time when this entry will expire (null means no expiration)
  final DateTime? expirationTime;
  
  /// Time when this entry was added to the cache
  final DateTime cachedAt;
  
  _CacheEntry({
    required this.data,
    this.expirationTime,
    required this.cachedAt,
  });
}

/// A provider for the [RouteCacheManager] singleton
final routeCacheManagerProvider = Provider<RouteCacheManager>(
  (ref) => RouteCacheManager(),
);

/// Extension on AsyncValue to provide easy cache interaction
extension AsyncValueCacheExtension<T> on AsyncValue<T> {
  /// Returns a cached version of this AsyncValue if available, otherwise returns this
  AsyncValue<T> cachedOr(RouteCacheManager cacheManager, String cacheKey) {
    final cachedData = cacheManager.getRouteData<T>(cacheKey);
    if (cachedData != null) {
      return AsyncValue.data(cachedData);
    }
    return this;
  }
} 