import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/route_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A class that adds caching capabilities to GoRouter
class CachedRouterHelper {
  /// The route cache manager
  final RouteCacheManager _cacheManager;
  
  /// Constructor
  CachedRouterHelper({
    required RouteCacheManager cacheManager,
  }) : _cacheManager = cacheManager;
  
  /// Check if a route is cached
  bool isCached(String path) {
    return _cacheManager.isCached(path);
  }
  
  /// Get a cached route if available
  Page<dynamic>? getCachedRoute(String path) {
    return _cacheManager.getCachedRoute(path);
  }
  
  /// Cache a route
  void cacheRoute(String path, Page<dynamic> page, {Duration? ttl}) {
    _cacheManager.cacheRoutePage(path, page, ttl: ttl);
  }
  
  /// Invalidate a cached route
  void invalidateRoute(String path) {
    _cacheManager.invalidateRoute(path);
  }
  
  /// Invalidate routes by pattern
  void invalidateRoutesByPattern(String pattern) {
    _cacheManager.invalidateRoutesByPattern(pattern);
  }
  
  /// Clean expired caches
  void cleanExpiredCaches() {
    _cacheManager.cleanExpiredCaches();
  }
  
  /// Clear all cached routes
  void clearCache() {
    _cacheManager.clearCache();
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return _cacheManager.getCacheStats();
  }
}

/// Create a route observer that caches routes as they are built
class CachingRouteObserver extends NavigatorObserver {
  /// The cache helper
  final CachedRouterHelper _cacheHelper;
  
  /// Constructor
  CachingRouteObserver({
    required CachedRouterHelper cacheHelper,
  }) : _cacheHelper = cacheHelper;
  
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Check if this is a page we should cache
    if (route is MaterialPageRoute) {
      final settings = route.settings;
      final path = _getPathFromSettings(settings);
      
      if (path != null && !_shouldSkipCaching(settings)) {
        // Create a page representation for caching
        final page = MaterialPage<dynamic>(
          key: ValueKey(path),
          name: settings.name,
          arguments: settings.arguments,
          child: route.builder(navigator!.context),
        );
        
        // Cache the page
        _cacheHelper.cacheRoute(path, page);
      }
    }
  }
  
  /// Get a caching path from route settings
  String? _getPathFromSettings(RouteSettings settings) {
    // Return the route name if available
    return settings.name;
  }
  
  /// Check if we should skip caching this route
  bool _shouldSkipCaching(RouteSettings settings) {
    final name = settings.name ?? '';
    
    // Avoid caching error pages or temporary pages
    return name.contains('error') || 
           name.contains('not_found') || 
           name.contains('loading');
  }
}

/// Extension to add caching capabilities to GoRouter
extension CachedGoRouter on GoRouter {
  /// Add route caching to this router
  void enableRouteCache(CachedRouterHelper cacheHelper) {
    // This would add the caching observer to the router's observers
    // and update the router configuration
    // Implementation is limited by GoRouter's API
  }
}

/// Provider for the cached router helper
final cachedRouterHelperProvider = Provider<CachedRouterHelper>((ref) {
  final cacheManager = ref.watch(routeCacheManagerProvider);
  return CachedRouterHelper(cacheManager: cacheManager);
});

/// Provider for the caching route observer
final cachingRouteObserverProvider = Provider<CachingRouteObserver>((ref) {
  final cacheHelper = ref.watch(cachedRouterHelperProvider);
  return CachingRouteObserver(cacheHelper: cacheHelper);
}); 