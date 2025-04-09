import 'package:hive_ui/core/cache/cache_ttl_config.dart';

/// Represents a cached entry with metadata for tracking its lifecycle
class CacheEntry<T> {
  /// The actual cached data
  final T data;
  
  /// When the entry was created/updated
  final DateTime createdAt;
  
  /// Time-to-live duration for this entry
  final Duration ttl;
  
  /// Number of times this entry has been accessed
  int accessCount = 0;
  
  /// Last time this entry was accessed
  DateTime? lastAccessedAt;
  
  /// Any additional metadata for this cache entry
  final Map<String, dynamic>? metadata;
  
  /// Create a new cache entry
  CacheEntry({
    required this.data,
    required this.ttl,
    DateTime? createdAt,
    this.metadata,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Create a cache entry with default TTL
  factory CacheEntry.withDefaultTTL({
    required T data,
    Map<String, dynamic>? metadata,
  }) {
    return CacheEntry(
      data: data,
      ttl: CacheTTLConfig.defaultTTL,
      metadata: metadata,
    );
  }
  
  /// Log that this entry was accessed
  void markAccessed() {
    accessCount++;
    lastAccessedAt = DateTime.now();
  }
  
  /// Check if this entry has expired based on its TTL
  bool get isExpired {
    final now = DateTime.now();
    final age = now.difference(createdAt);
    return age > ttl;
  }
  
  /// Get the expiration date of this entry
  DateTime get expiresAt => createdAt.add(ttl);
  
  /// Get the remaining time until expiration
  Duration get timeRemaining {
    final now = DateTime.now();
    final expiresAt = createdAt.add(ttl);
    return now.isBefore(expiresAt) ? expiresAt.difference(now) : Duration.zero;
  }
  
  /// Get percentage of TTL consumed
  double get ttlPercentageConsumed {
    final age = DateTime.now().difference(createdAt);
    return (age.inMilliseconds / ttl.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }
  
  /// Create a copy of this entry with new data but preserved metadata
  CacheEntry<T> copyWithNewData(T newData) {
    return CacheEntry<T>(
      data: newData,
      ttl: ttl,
      createdAt: DateTime.now(),
      metadata: metadata,
    );
  }
  
  /// Create a copy of this entry with extended TTL
  CacheEntry<T> copyWithExtendedTTL(Duration newTtl) {
    return CacheEntry<T>(
      data: data,
      ttl: newTtl,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
  
  @override
  String toString() {
    return 'CacheEntry<$T>(created: $createdAt, ttl: $ttl, access count: $accessCount, expires: $expiresAt)';
  }
} 