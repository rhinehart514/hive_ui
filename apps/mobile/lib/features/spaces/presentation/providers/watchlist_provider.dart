import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/firebase_watchlist_repository.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/watchlist_repository.dart';

/// Provider for the spaces data source
final spacesDataSourceProvider = Provider<SpacesDataSource>((ref) {
  return SpacesFirestoreDataSource();
});

/// Provider for the watchlist repository
final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  final spacesDataSource = ref.watch(spacesDataSourceProvider);
  return FirebaseWatchlistRepository(spacesDataSource: spacesDataSource);
});

/// Provider for list of watched spaces
final watchedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.getWatchedSpaces();
});

/// Provider for streaming watched spaces
final watchedSpacesStreamProvider = StreamProvider<List<SpaceEntity>>((ref) {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.watchWatchedSpaces();
});

/// Provider to check if a specific space is watched
final isWatchingSpaceProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.isWatchingSpace(spaceId);
});

/// Provider for watcher count of a specific space
final watcherCountProvider = FutureProvider.family<int, String>((ref, spaceId) async {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.getWatcherCount(spaceId);
});

/// Provider for streaming watcher count of a specific space
final watcherCountStreamProvider = StreamProvider.family<int, String>((ref, spaceId) {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.watchWatcherCount(spaceId);
});

/// Provider for watchlist-based recommendations
final watchlistRecommendationsProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final watchlistRepository = ref.watch(watchlistRepositoryProvider);
  return watchlistRepository.getWatchlistRecommendations();
});

/// Controller to manage watchlist actions
class WatchlistController extends StateNotifier<AsyncValue<void>> {
  final WatchlistRepository _repository;
  
  WatchlistController(this._repository) : super(const AsyncValue.data(null));
  
  /// Add a space to the watchlist
  Future<bool> watchSpace(String spaceId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.watchSpace(spaceId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  /// Remove a space from the watchlist
  Future<bool> unwatchSpace(String spaceId) async {
    state = const AsyncValue.loading();
    try {
      final result = await _repository.unwatchSpace(spaceId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
  
  /// Toggle watchlist status for a space
  Future<bool> toggleWatchStatus(String spaceId) async {
    state = const AsyncValue.loading();
    try {
      final isWatching = await _repository.isWatchingSpace(spaceId);
      final result = isWatching
          ? await _repository.unwatchSpace(spaceId)
          : await _repository.watchSpace(spaceId);
      state = const AsyncValue.data(null);
      return result;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

/// Provider for the watchlist controller
final watchlistControllerProvider = StateNotifierProvider<WatchlistController, AsyncValue<void>>((ref) {
  final repository = ref.watch(watchlistRepositoryProvider);
  return WatchlistController(repository);
}); 