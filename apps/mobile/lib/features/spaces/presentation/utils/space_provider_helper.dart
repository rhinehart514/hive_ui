import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_async_providers.dart';

/// Helper class for components to access space data with proper AsyncValue handling
class SpaceProviderHelper {
  final WidgetRef ref;

  SpaceProviderHelper(this.ref);

  /// Get all spaces with AsyncValue.when support
  AsyncValue<Map<String, SpaceEntity>> getAllSpaces() {
    return ref.watch(spacesAsyncProvider);
  }

  /// Get user joined spaces with AsyncValue.when support
  AsyncValue<List<SpaceEntity>> getUserSpaces() {
    return ref.watch(userSpacesAsyncProvider);
  }

  /// Get spaces by category with AsyncValue.when support
  AsyncValue<List<SpaceEntity>> getSpacesByCategory(String category) {
    return ref.watch(spacesByCategoryAsyncProvider(category));
  }

  /// Get trending spaces with AsyncValue.when support
  AsyncValue<List<SpaceEntity>> getTrendingSpaces() {
    return ref.watch(trendingSpacesAsyncProvider);
  }
  
  /// Get space metrics with AsyncValue.when support
  AsyncValue<Map<String, SpaceMetricsEntity>> getAllSpaceMetrics() {
    return ref.watch(spaceMetricsAsyncProvider);
  }
  
  /// Helper to get a single space by ID with caching
  AsyncValue<SpaceEntity?> getSpaceById(String spaceId) {
    final spacesAsync = ref.watch(spacesAsyncProvider);
    
    return spacesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (spaces) => AsyncValue.data(spaces[spaceId]),
    );
  }
  
  /// Helper to get metrics for a space by ID with caching
  AsyncValue<SpaceMetricsEntity?> getSpaceMetricsById(String spaceId) {
    final metricsAsync = ref.watch(spaceMetricsAsyncProvider);
    
    return metricsAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (metrics) => AsyncValue.data(metrics[spaceId]),
    );
  }
  
  /// Get a list of space categories
  AsyncValue<List<String>> getSpaceCategories() {
    final spacesAsync = ref.watch(spacesAsyncProvider);
    
    return spacesAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (spaces) {
        final Set<String> categories = {};
        for (final space in spaces.values) {
          categories.add(space.spaceType.toString());
        }
        return AsyncValue.data(categories.toList());
      },
    );
  }
  
  /// Check if a space is in cache
  bool isSpaceInCache(String spaceId) {
    final spacesAsync = ref.read(spacesAsyncProvider);
    return spacesAsync.maybeWhen(
      data: (spaces) => spaces.containsKey(spaceId),
      orElse: () => false,
    );
  }
} 