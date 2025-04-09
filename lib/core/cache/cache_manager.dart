import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/refresh/global_refresh_controller.dart';
import 'package:hive_ui/core/cache/cache_entry.dart';
import 'package:hive_ui/core/cache/cache_ttl_config.dart';
import 'package:hive_ui/core/cache/cache_analytics.dart';

/// Manages cache invalidation and TTL-based expiration across the app
class CacheManager {
  static final CacheManager _instance = CacheManager._internal();
  
  factory CacheManager() => _instance;
  
  // In-memory cache storage with generic type support
  final Map<String, CacheEntry<dynamic>> _cache = {};
  
  // Last invalidation timestamps for each cache key
  final Map<String, DateTime> _lastInvalidationTimes = {};
  
  // Analytics tracker
  final CacheAnalytics _analytics = CacheAnalytics();
  
  // Maximum cache entries before cleanup is triggered
  static const int _maxCacheEntries = 1000;
  
  // Timer for periodic cleanup
  Timer? _cleanupTimer;
  
  CacheManager._internal() {
    _setupListeners();
    _startCleanupTimer();
  }
  
  void _setupListeners() {
    // Listen for events that should invalidate caches
    AppEventBus().on<RsvpStatusChangedEvent>().listen((event) {
      invalidateCache('event:${event.eventId}');
      invalidateCache('user:${event.userId}:events');
    });
    
    AppEventBus().on<ProfileUpdatedEvent>().listen((event) {
      invalidateCache('user:${event.userId}');
      invalidateCache('user:${event.userId}:events');
    });
    
    AppEventBus().on<EventUpdatedEvent>().listen((event) {
      invalidateCache('event:${event.eventId}');
      invalidateCache('events');
    });
    
    // Handle Space membership changes
    AppEventBus().on<SpaceMembershipChangedEvent>().listen((event) {
      invalidateCache('space:${event.spaceId}');
      invalidateCache('space:${event.spaceId}:members');
      invalidateCache('user:${event.userId}:spaces');
      invalidateCache('spaces');
    });
    
    // Handle Space updates
    AppEventBus().on<SpaceUpdatedEvent>().listen((event) {
      invalidateCache('space:${event.spaceId}');
      invalidateCache('spaces');
    });
    
    // Handle new events
    AppEventBus().on<EventCreatedEvent>().listen((event) {
      invalidateCache('events');
      invalidateCache('space:${event.spaceId}:events');
      invalidateCache('feed');
    });
    
    // Handle friend requests
    AppEventBus().on<FriendRequestSentEvent>().listen((event) {
      invalidateCache('user:${event.senderId}:friends');
      invalidateCache('user:${event.receiverId}:requests');
    });
    
    // Handle friend request responses
    AppEventBus().on<FriendRequestRespondedEvent>().listen((event) {
      invalidateCache('user:${event.responderId}:friends');
      invalidateCache('user:${event.requesterId}:friends');
      invalidateCache('user:${event.responderId}:requests');
    });
    
    // Handle content reposts
    AppEventBus().on<ContentRepostedEvent>().listen((event) {
      invalidateCache('${event.contentType}:${event.contentId}');
      invalidateCache('user:${event.userId}:activity');
      invalidateCache('feed');
    });
    
    AppEventBus().on<GlobalRefreshEvent>().listen((event) {
      switch (event.target) {
        case RefreshTarget.feed:
          invalidateCache('feed');
          break;
        case RefreshTarget.events:
          invalidateCache('events');
          break;
        case RefreshTarget.profile:
          invalidateCache('profile');
          break;
        case RefreshTarget.spaces:
          invalidateCache('spaces');
          break;
        case RefreshTarget.all:
          invalidateCache('feed');
          invalidateCache('events');
          invalidateCache('profile');
          invalidateCache('spaces');
          break;
      }
    });
  }
  
  /// Start timer for periodic cache cleanup
  void _startCleanupTimer() {
    // Run cleanup every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performCleanup();
    });
  }
  
  /// Perform cache cleanup
  void _performCleanup() {
    final expiredEntries = <String>[];
    
    // Find expired entries
    for (final entry in _cache.entries) {
      if (_cache[entry.key]!.isExpired) {
        expiredEntries.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredEntries) {
      _cache.remove(key);
      _analytics.recordEviction(key);
    }
    
    if (expiredEntries.isNotEmpty) {
      debugPrint('🧹 CacheManager: Removed ${expiredEntries.length} expired entries');
    }
    
    // If cache is still too large, remove least recently accessed entries
    if (_cache.length > _maxCacheEntries) {
      final entriesToRemove = _cache.length - _maxCacheEntries;
      
      final sortedEntries = _cache.entries.toList()
        ..sort((a, b) {
          final lastAccessedA = a.value.lastAccessedAt;
          final lastAccessedB = b.value.lastAccessedAt;
          
          if (lastAccessedA == null && lastAccessedB == null) {
            return 0;
          } else if (lastAccessedA == null) {
            return -1;
          } else if (lastAccessedB == null) {
            return 1;
          } else {
            return lastAccessedA.compareTo(lastAccessedB);
          }
        });
      
      final keysToRemove = sortedEntries
          .take(entriesToRemove)
          .map((e) => e.key)
          .toList();
          
      for (final key in keysToRemove) {
        _cache.remove(key);
        _analytics.recordEviction(key);
      }
      
      debugPrint('🧹 CacheManager: Removed $entriesToRemove least recently accessed entries');
    }
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
  }
  
  /// Put a value in the cache with a specific TTL
  void put<T>(String cacheKey, T value, {Duration? ttl}) {
    final entry = CacheEntry<T>(
      data: value,
      ttl: ttl ?? _getTTLForKey(cacheKey),
    );
    
    _cache[cacheKey] = entry;
    _analytics.recordPut(cacheKey);
    
    if (_cache.length > _maxCacheEntries * 1.2) {
      // Trigger immediate cleanup if cache is getting too big
      _performCleanup();
    }
  }
  
  /// Get a value from the cache
  T? get<T>(String cacheKey) {
    final entry = _cache[cacheKey];
    final startTime = DateTime.now();
    
    if (entry == null) {
      _analytics.recordMiss(cacheKey);
      return null;
    }
    
    // Check if entry has been invalidated or expired
    if (!isCacheValid(cacheKey, entry.createdAt) || entry.isExpired) {
      _cache.remove(cacheKey);
      _analytics.recordMiss(cacheKey);
      return null;
    }
    
    // Update access statistics
    entry.markAccessed();
    _analytics.recordHit(cacheKey);
    _analytics.recordAccessTime(
      cacheKey, 
      DateTime.now().difference(startTime),
    );
    
    // Ensure type safety
    if (entry.data is T) {
      return entry.data as T;
    } else {
      debugPrint('⚠️ CacheManager: Type mismatch for key "$cacheKey". Expected $T but got ${entry.data.runtimeType}');
      return null;
    }
  }
  
  /// Get a value from the cache, or compute it if not present
  Future<T> getOrCompute<T>(
    String cacheKey, 
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    final cachedValue = get<T>(cacheKey);
    if (cachedValue != null) {
      return cachedValue;
    }
    
    // Compute the value
    final startTime = DateTime.now();
    final computedValue = await compute();
    final computeTime = DateTime.now().difference(startTime);
    
    // Cache the computed value
    put<T>(cacheKey, computedValue, ttl: ttl);
    
    return computedValue;
  }
  
  /// Invalidate a specific cache
  void invalidateCache(String cacheKey) {
    // Handle prefix-based invalidation
    if (cacheKey.endsWith('*')) {
      final prefix = cacheKey.substring(0, cacheKey.length - 1);
      final keysToInvalidate = _cache.keys
          .where((key) => key.startsWith(prefix))
          .toList();
      
      for (final key in keysToInvalidate) {
        _lastInvalidationTimes[key] = DateTime.now();
        _cache.remove(key);
        _analytics.recordInvalidation(key);
      }
      
      debugPrint('🧹 CacheManager: Invalidated ${keysToInvalidate.length} cache entries with prefix "$prefix"');
    } else {
      _lastInvalidationTimes[cacheKey] = DateTime.now();
      _cache.remove(cacheKey);
      _analytics.recordInvalidation(cacheKey);
      debugPrint('🧹 CacheManager: Invalidated cache for "$cacheKey"');
    }
  }
  
  /// Clear the entire cache
  void clearCache() {
    final count = _cache.length;
    _cache.clear();
    _lastInvalidationTimes.clear();
    debugPrint('🧹 CacheManager: Cleared entire cache ($count entries)');
  }
  
  /// Check if a cache is valid
  bool isCacheValid(String cacheKey, DateTime cacheTime) {
    final lastInvalidation = _lastInvalidationTimes[cacheKey];
    if (lastInvalidation == null) return true;
    return cacheTime.isAfter(lastInvalidation);
  }
  
  /// Get time since last invalidation
  Duration? timeSinceInvalidation(String cacheKey) {
    final lastInvalidation = _lastInvalidationTimes[cacheKey];
    if (lastInvalidation == null) return null;
    return DateTime.now().difference(lastInvalidation);
  }
  
  /// Get the appropriate TTL for a cache key based on its pattern
  Duration _getTTLForKey(String cacheKey) {
    // User-related TTLs
    if (cacheKey.startsWith('user:')) {
      if (cacheKey.endsWith(':profile')) {
        return CacheTTLConfig.userProfile;
      } else if (cacheKey.endsWith(':friends')) {
        return CacheTTLConfig.userFriends;
      } else if (cacheKey.endsWith(':spaces')) {
        return CacheTTLConfig.userSpaces;
      } else if (cacheKey.endsWith(':events')) {
        return CacheTTLConfig.userSavedEvents;
      } else if (cacheKey.endsWith(':requests')) {
        return CacheTTLConfig.friendRequests;
      }
      return CacheTTLConfig.userProfile;
    }
    
    // Event-related TTLs
    if (cacheKey.startsWith('event:')) {
      return CacheTTLConfig.eventDetails;
    } else if (cacheKey == 'events') {
      return CacheTTLConfig.eventsFeed;
    } else if (cacheKey.contains(':events')) {
      return CacheTTLConfig.eventsBySpace;
    } else if (cacheKey.contains('rsvp:')) {
      return CacheTTLConfig.rsvpStatus;
    }
    
    // Space-related TTLs
    if (cacheKey.startsWith('space:')) {
      if (cacheKey.endsWith(':members')) {
        return CacheTTLConfig.spaceMembers;
      }
      return CacheTTLConfig.spaceDetails;
    } else if (cacheKey == 'spaces') {
      return CacheTTLConfig.spacesList;
    }
    
    // Feed and content-related TTLs
    if (cacheKey == 'feed') {
      return CacheTTLConfig.feedContent;
    } else if (cacheKey.contains('interaction')) {
      return CacheTTLConfig.contentInteractions;
    }
    
    // Default TTL for unrecognized patterns
    return CacheTTLConfig.defaultTTL;
  }
  
  /// Get cache stats for analysis
  Map<String, dynamic> getStats() {
    return {
      'entryCount': _cache.length,
      'analytics': _analytics.getSummary(),
      'memoryUsage': 'Unknown', // Not easy to measure in Dart
      'oldestEntry': _cache.isEmpty 
          ? null 
          : _cache.entries
              .map((e) => e.value.createdAt)
              .reduce((a, b) => a.isBefore(b) ? a : b)
              .toIso8601String(),
      'keysByPrefix': _getKeyCountByPrefix(),
    };
  }
  
  /// Get distribution of cache keys by prefix
  Map<String, int> _getKeyCountByPrefix() {
    final results = <String, int>{};
    
    for (final key in _cache.keys) {
      final parts = key.split(':');
      if (parts.isNotEmpty) {
        final prefix = parts[0];
        results[prefix] = (results[prefix] ?? 0) + 1;
      }
    }
    
    return results;
  }
  
  /// Log cache statistics
  void logStats() {
    debugPrint('📊 CACHE MANAGER STATISTICS');
    debugPrint('Current cache entries: ${_cache.length}');
    
    final stats = getStats();
    final keysByPrefix = stats['keysByPrefix'] as Map<String, int>;
    
    debugPrint('Distribution by prefix:');
    for (final entry in keysByPrefix.entries) {
      debugPrint('  ${entry.key}: ${entry.value} entries');
    }
    
    _analytics.logSummary();
  }
  
  /// Get the CacheAnalytics instance
  CacheAnalytics get analytics => _analytics;
} 