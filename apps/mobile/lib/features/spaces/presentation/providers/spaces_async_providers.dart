import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_metrics_entity.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Provider for all spaces with proper state handling
/// Wraps the base provider to maintain AsyncValue functionality
final spacesAsyncProvider = Provider<AsyncValue<Map<String, SpaceEntity>>>((ref) {
  try {
    final spaces = ref.watch(spacesProvider);
    return AsyncValue.data(spaces);
  } catch (e, stack) {
    return AsyncValue.error(e, stack);
  }
});

/// Provider for user joined spaces with proper state handling
final userSpacesAsyncProvider = Provider<AsyncValue<List<SpaceEntity>>>((ref) {
  // Watch the base spaces provider to react to changes
  final spacesAsync = ref.watch(spacesAsyncProvider);
  
  return spacesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (spaces) {
      final userSpaces = spaces.values
          .where((space) => space.isJoined)
          .toList();
      return AsyncValue.data(userSpaces);
    }
  );
});

/// Provider for spaces by category with proper state handling
final spacesByCategoryAsyncProvider = Provider.family<AsyncValue<List<SpaceEntity>>, String>((ref, category) {
  final spacesAsync = ref.watch(spacesAsyncProvider);
  
  return spacesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (spaces) {
      final categorySpaces = spaces.values
          .where((space) => space.spaceType.toString().contains(category))
          .toList();
      return AsyncValue.data(categorySpaces);
    }
  );
});

/// Provider for trending spaces with proper state handling
final trendingSpacesAsyncProvider = Provider<AsyncValue<List<SpaceEntity>>>((ref) {
  final spacesAsync = ref.watch(spacesAsyncProvider);
  
  return spacesAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (err, stack) => AsyncValue.error(err, stack),
    data: (spaces) {
      final trendingSpaces = spaces.values
          .where((space) => space.metrics.isTrending)
          .toList();
      
      // Sort by engagement score
      trendingSpaces.sort((a, b) => 
          b.metrics.engagementScore.compareTo(a.metrics.engagementScore));
      
      return AsyncValue.data(trendingSpaces.take(10).toList());
    }
  );
});

/// Provider for space metrics with proper state handling
final spaceMetricsAsyncProvider = Provider<AsyncValue<Map<String, SpaceMetricsEntity>>>((ref) {
  try {
    final metrics = ref.watch(spaceMetricsProvider);
    return AsyncValue.data(metrics);
  } catch (e, stack) {
    return AsyncValue.error(e, stack);
  }
});

/// Provider for getting a space by ID
final spaceByIdProvider = FutureProvider.family<SpaceEntity?, String>((ref, spaceId) async {
  try {
    final repository = ref.read(spaceRepositoryProvider);
    final spaceType = ref.read(spaceTypeProvider(spaceId));
    return await repository.getSpaceById(spaceId, spaceType: spaceType);
  } catch (e) {
    debugPrint('Error in spaceByIdProvider: $e');
    return null;
  }
});

/// Provider for storing space types by ID
final spaceTypeProvider = StateProvider.family<String?, String>((ref, spaceId) => null); 