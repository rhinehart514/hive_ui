import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ui/core/navigation/cached_router_delegate.dart';
import 'package:hive_ui/core/navigation/route_cache_manager.dart';
import 'package:hive_ui/core/navigation/router_config.dart';
import 'dart:async';

/// Service for managing route caching
class RouteCachingService {
  /// The cache helper
  final CachedRouterHelper _cacheHelper;
  
  /// Router instance
  final GoRouter _router;
  
  /// Timer for periodic cache cleanup
  Timer? _cleanupTimer;
  
  /// Constructor
  RouteCachingService({
    required CachedRouterHelper cacheHelper,
    required GoRouter router,
  })  : _cacheHelper = cacheHelper,
        _router = router {
    _startCleanupTimer();
  }
  
  /// Initialize route caching
  void initialize() {
    // Enable caching on the router
    _router.enableRouteCache(_cacheHelper);
    
    // Log initialization
    debugPrint('🎯 RouteCachingService: Route caching initialized');
  }
  
  /// Cache a route
  void cacheRoute(String path, Page<dynamic> page, {Duration? ttl}) {
    _cacheHelper.cacheRoute(path, page, ttl: ttl);
  }
  
  /// Check if a route is cached
  bool isCached(String path) {
    return _cacheHelper.isCached(path);
  }
  
  /// Get a cached route
  Page<dynamic>? getCachedRoute(String path) {
    return _cacheHelper.getCachedRoute(path);
  }
  
  /// Invalidate a specific route
  void invalidateRoute(String path) {
    _cacheHelper.invalidateRoute(path);
  }
  
  /// Invalidate routes by pattern
  void invalidateRoutesByPattern(String pattern) {
    _cacheHelper.invalidateRoutesByPattern(pattern);
  }
  
  /// Invalidate feed routes
  void invalidateFeedRoutes() {
    invalidateRoutesByPattern('/home');
  }
  
  /// Invalidate profile routes
  void invalidateProfileRoutes() {
    invalidateRoutesByPattern('/profile');
  }
  
  /// Invalidate event routes
  void invalidateEventRoutes() {
    invalidateRoutesByPattern('/event/');
  }
  
  /// Invalidate space routes
  void invalidateSpaceRoutes() {
    invalidateRoutesByPattern('/spaces');
  }
  
  /// Invalidate organization routes
  void invalidateOrganizationRoutes() {
    invalidateRoutesByPattern('/organizations');
  }
  
  /// Clear all cached routes
  void clearCache() {
    _cacheHelper.clearCache();
  }
  
  /// Get cache statistics
  Map<String, dynamic> getStats() {
    return _cacheHelper.getStats();
  }
  
  /// Start cleanup timer
  void _startCleanupTimer() {
    // Clean up expired caches every 5 minutes
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      debugPrint('🧹 RouteCachingService: Running scheduled cache cleanup');
      _cacheHelper.cleanExpiredCaches();
    });
  }
  
  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
  }
}

/// Provider for the route caching service
final routeCachingServiceProvider = Provider<RouteCachingService>((ref) {
  final cacheHelper = ref.watch(cachedRouterHelperProvider);
  final router = ref.watch(routerProvider);
  
  final service = RouteCachingService(
    cacheHelper: cacheHelper,
    router: router,
  );
  
  // Initialize the service
  service.initialize();
  
  // Ensure cleanup on dispose
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
}); 