import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/navigation/route_caching_service.dart';

/// Structure for cached content
class CachedRouteContent {
  /// The cached widget
  final Widget widget;
  
  /// When this cache was created
  final DateTime timestamp;
  
  /// Constructor
  CachedRouteContent({
    required this.widget,
    required this.timestamp,
  });
}

/// A widget that leverages route caching for improved performance
class RouteCachedProviderBuilder<T> extends ConsumerWidget {
  /// Unique cache key for this route
  final String cacheKey;
  
  /// The provider to watch
  final ProviderBase<AsyncValue<T>> provider;
  
  /// Builder function for success state
  final Widget Function(BuildContext, T) builder;
  
  /// Builder function for loading state (optional)
  final Widget Function(BuildContext)? loadingBuilder;
  
  /// Builder function for error state (optional)
  final Widget Function(BuildContext, Object?, StackTrace?)? errorBuilder;
  
  /// TTL for caching (optional)
  final Duration? cacheTTL;
  
  /// Constructor
  const RouteCachedProviderBuilder({
    Key? key,
    required this.cacheKey,
    required this.provider,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.cacheTTL,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if we have a cached version
    final cachingService = ref.watch(routeCachingServiceProvider);
    
    // Try to use cached data if possible
    final state = ref.watch(provider);
    
    return state.when(
      data: (data) {
        final widget = builder(context, data);
        
        // Cache the built widget for future use
        _cacheWidget(cachingService, widget);
        
        return widget;
      },
      loading: () {
        // Check if we have a cached version during loading
        if (cachingService.isCached(cacheKey)) {
          final cachedPage = cachingService.getCachedRoute(cacheKey);
          if (cachedPage != null && cachedPage is MaterialPage) {
            // Use cached version with loading indicator overlay
            return Stack(
              children: [
                cachedPage.child,
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            );
          }
        }
        
        // Fallback to standard loading
        return loadingBuilder != null
            ? loadingBuilder!(context)
            : const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        // Check if we have a cached version during error
        if (cachingService.isCached(cacheKey)) {
          final cachedPage = cachingService.getCachedRoute(cacheKey);
          if (cachedPage != null && cachedPage is MaterialPage) {
            // Use cached version with error indicator overlay
            return Stack(
              children: [
                cachedPage.child,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      'Error loading latest data. Showing cached version.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
        }
        
        // Fallback to standard error
        return errorBuilder != null
            ? errorBuilder!(context, error, stackTrace)
            : Center(child: Text('Error: $error'));
      },
    );
  }
  
  /// Cache the current widget
  void _cacheWidget(RouteCachingService cachingService, Widget widget) {
    // Create a material page for caching
    final page = MaterialPage<dynamic>(
      key: ValueKey(cacheKey),
      name: cacheKey,
      child: widget,
    );
    
    // Cache the page
    cachingService.cacheRoute(cacheKey, page, ttl: cacheTTL);
  }
}

/// Extension method to add route caching to AsyncValue
extension RouteCachedAsyncValue<T> on AsyncValue<T> {
  /// Build with route caching support
  Widget buildWithRouteCache(
    BuildContext context,
    WidgetRef ref,
    String cacheKey, {
    required Widget Function(T) data,
    Widget Function()? loading,
    Widget Function(Object?, StackTrace?)? error,
    Duration? cacheTTL,
  }) {
    // Check if we have a cached version
    final cachingService = ref.watch(routeCachingServiceProvider);
    
    return when(
      data: (value) {
        final widget = data(value);
        
        // Cache the built widget for future use
        _cacheWidget(context, cachingService, cacheKey, widget, cacheTTL);
        
        return widget;
      },
      loading: () {
        // Check if we have a cached version during loading
        if (cachingService.isCached(cacheKey)) {
          final cachedPage = cachingService.getCachedRoute(cacheKey);
          if (cachedPage != null && cachedPage is MaterialPage) {
            // Use cached version with loading indicator overlay
            return Stack(
              children: [
                cachedPage.child,
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.1),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
              ],
            );
          }
        }
        
        // Fallback to standard loading
        return loading != null
            ? loading()
            : const Center(child: CircularProgressIndicator());
      },
      error: (e, st) {
        // Check if we have a cached version during error
        if (cachingService.isCached(cacheKey)) {
          final cachedPage = cachingService.getCachedRoute(cacheKey);
          if (cachedPage != null && cachedPage is MaterialPage) {
            // Use cached version with error indicator overlay
            return Stack(
              children: [
                cachedPage.child,
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.red.withOpacity(0.8),
                    padding: const EdgeInsets.all(8.0),
                    child: const Text(
                      'Error loading latest data. Showing cached version.',
                      style: TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            );
          }
        }
        
        // Fallback to standard error
        return error != null
            ? error(e, st)
            : Center(child: Text('Error: $e'));
      },
    );
  }
  
  /// Cache the current widget
  void _cacheWidget(
    BuildContext context,
    RouteCachingService cachingService,
    String cacheKey,
    Widget widget,
    Duration? cacheTTL,
  ) {
    // Create a material page for caching
    final page = MaterialPage<dynamic>(
      key: ValueKey(cacheKey),
      name: cacheKey,
      child: widget,
    );
    
    // Cache the page
    cachingService.cacheRoute(cacheKey, page, ttl: cacheTTL);
  }
} 