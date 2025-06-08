import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_analytics.dart';

/// Provider for the global cache manager instance
final cacheManagerProvider = Provider<CacheManager>((ref) {
  final cacheManager = CacheManager();
  
  // Ensure cleanup when the provider is disposed
  ref.onDispose(() {
    cacheManager.dispose();
  });
  
  return cacheManager;
});

/// Provider for accessing cache analytics
final cacheAnalyticsProvider = Provider<CacheAnalytics>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return cacheManager.analytics;
});

/// Provider to get current cache statistics
final cacheStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final cacheManager = ref.watch(cacheManagerProvider);
  return cacheManager.getStats();
});

/// Factory function to create a provider family for cached data
/// 
/// Usage example:
/// ```dart
/// final userProfileProvider = createCachedProvider<UserProfile, String>(
///   keyBuilder: (userId) => 'user:$userId:profile',
///   fetcher: (ref, userId) => userRepository.getProfile(userId),
///   ttl: CacheTTLConfig.userProfile,
/// );
/// ```
ProviderFamily<AsyncValue<T>, P> createCachedProvider<T, P>({
  required String Function(P param) keyBuilder,
  required Future<T> Function(Ref ref, P param) fetcher,
  Duration? ttl,
}) {
  return Provider.family<AsyncValue<T>, P>((ref, param) {
    final cacheKey = keyBuilder(param);
    
    final cachedData = ref.watch(cacheManagerProvider).get<T>(cacheKey);
    if (cachedData != null) {
      return AsyncValue.data(cachedData);
    }
    
    // Create a unique key for the internal fetch provider
    final fetchKey = _FetchParams<T>(
      key: cacheKey,
      fetch: () => fetcher(ref, param),
      ttl: ttl,
    );
    
    return ref.watch(_createFetchProvider(fetchKey));
  });
}

/// Parameters for fetch operations
class _FetchParams<T> {
  final String key;
  final Future<T> Function() fetch;
  final Duration? ttl;
  
  _FetchParams({required this.key, required this.fetch, this.ttl});
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _FetchParams<T> &&
          runtimeType == other.runtimeType &&
          key == other.key;
  
  @override
  int get hashCode => key.hashCode;
}

/// Creates a fetch provider for the given parameters
AutoDisposeFutureProvider<T> _createFetchProvider<T>(_FetchParams<T> params) {
  return FutureProvider.autoDispose<T>((ref) async {
    final data = await params.fetch();
    
    // Cache the result
    ref.watch(cacheManagerProvider).put<T>(
      params.key, 
      data, 
      ttl: params.ttl,
    );
    
    return data;
  });
} 