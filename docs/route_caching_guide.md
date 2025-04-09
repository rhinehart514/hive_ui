# Route Caching in HIVE UI

This guide explains how the route caching system works in HIVE UI to improve performance and user experience.

## Overview

The route caching system allows the application to:

1. Cache rendered routes to improve navigation speed
2. Show cached content during loading states for better UX
3. Provide fallback content during error states
4. Intelligently invalidate cached routes when data changes

## Components

The route caching system consists of several components:

- **RouteCacheManager**: Core caching logic for storing and retrieving pages
- **CachedRouterHelper**: Helper class for working with the cache manager
- **RouteCachingService**: High-level service for managing route caching
- **RouteCachedProviderBuilder**: Widget to easily use cached data in the UI
- **RouteCachedAsyncValue**: Extension methods for AsyncValue to support caching

## Cache TTL Configuration

Different route types have different cache lifetimes:

| Route Type | TTL | Purpose |
|------------|-----|---------|
| Feed routes | 3 minutes | Content updates frequently |
| Profile routes | 10 minutes | Profile data changes infrequently |
| Event routes | 5 minutes | Event details may update occasionally |
| Space routes | 8 minutes | Space content is relatively stable |
| Organization routes | 8 minutes | Organization info changes infrequently |
| Settings routes | 15 minutes | Settings rarely change during sessions |

## Using Route Caching

### Basic Usage

To use route caching in a widget, wrap it with the `RouteCachedProviderBuilder`:

```dart
RouteCachedProviderBuilder<UserProfile>(
  cacheKey: 'profile_${userId}',
  provider: userProfileProvider(userId),
  builder: (context, profile) {
    return ProfileView(profile: profile);
  },
  loadingBuilder: (context) {
    return const ProfileLoadingView();
  },
  errorBuilder: (context, error, stackTrace) {
    return ProfileErrorView(error: error);
  },
)
```

### Extension Method Usage

Alternatively, use the extension method on AsyncValue:

```dart
final profileState = ref.watch(userProfileProvider(userId));

return profileState.buildWithRouteCache(
  context,
  ref,
  'profile_${userId}',
  data: (profile) => ProfileView(profile: profile),
  loading: () => const ProfileLoadingView(),
  error: (error, stackTrace) => ProfileErrorView(error: error),
);
```

### Invalidating Routes

When data changes, you should invalidate related routes:

```dart
// After updating a profile
void updateProfile(UserProfile profile) async {
  await profileRepository.updateProfile(profile);
  
  // Invalidate related routes
  ref.read(routeCachingServiceProvider).invalidateProfileRoutes();
}
```

You can also invalidate specific routes or patterns:

```dart
final cachingService = ref.read(routeCachingServiceProvider);

// Invalidate a specific route
cachingService.invalidateRoute('profile_${userId}');

// Invalidate routes matching a pattern
cachingService.invalidateRoutesByPattern('/profile');
```

## Performance Benefits

The route caching system provides several performance benefits:

1. **Faster Navigation**: Cached routes can be displayed immediately when navigating
2. **Smooth Loading States**: Users see cached content during loading for a better experience
3. **Offline Resilience**: Cached content is available during connectivity issues
4. **Reduced Widget Rebuilds**: Fewer rebuilds mean better performance
5. **Lower Memory Usage**: LRU cache eviction keeps memory usage reasonable

## Best Practices

1. **Use Meaningful Cache Keys**: Include identifiers in cache keys (e.g., `profile_${userId}`)
2. **Set Appropriate TTLs**: Match TTL to how frequently data changes
3. **Invalidate Correctly**: Invalidate caches when underlying data changes
4. **Don't Cache Everything**: Prioritize caching complex UIs and slow-loading data
5. **Test Cache Behavior**: Verify your app works correctly with and without cached content

## Example: Feed Page Caching

```dart
class FeedPage extends ConsumerWidget {
  const FeedPage({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RouteCachedProviderBuilder<List<FeedItem>>(
      cacheKey: 'home_feed',
      provider: feedItemsProvider,
      cacheTTL: RouteCacheTTL.feedRoute,
      builder: (context, items) {
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => FeedItemCard(item: items[index]),
        );
      },
    );
  }
}
```

## Technical Implementation Details

The caching system uses an LRU (Least Recently Used) algorithm to evict old entries when the cache reaches capacity. Each cache entry has:

- The rendered widget/page
- A timestamp of when it was cached
- An expiration time based on its TTL

When a route is requested:
1. Check if it exists in the cache and is not expired
2. If found, return the cached route
3. If not found or expired, generate the route and cache it
4. Periodically clean up expired cache entries

The system also handles cache invalidation through explicit API calls or automatic TTL expiration.

## Troubleshooting

If you encounter issues with route caching:

1. **Stale Data**: If you see outdated information, reduce TTL or add proper invalidation
2. **Memory Issues**: If memory usage is high, reduce `_maxCacheSize` in RouteCacheManager
3. **Missing Cache Hits**: Ensure consistent cache keys between caching and retrieval
4. **Performance Problems**: Check for unnecessary cache invalidation 