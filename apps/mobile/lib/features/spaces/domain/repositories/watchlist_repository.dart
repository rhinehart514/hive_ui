import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Repository interface for managing user's watchlist (soft affiliations with spaces)
abstract class WatchlistRepository {
  /// Add a space to user's watchlist
  ///
  /// [spaceId] The ID of the space to watch
  /// [userId] Optional user ID. If not provided, uses the current user.
  ///
  /// Returns true if successful, false otherwise
  Future<bool> watchSpace(String spaceId, {String? userId});
  
  /// Remove a space from user's watchlist
  ///
  /// [spaceId] The ID of the space to unwatch
  /// [userId] Optional user ID. If not provided, uses the current user.
  ///
  /// Returns true if successful, false otherwise
  Future<bool> unwatchSpace(String spaceId, {String? userId});
  
  /// Check if a user is watching a space
  ///
  /// [spaceId] The ID of the space to check
  /// [userId] Optional user ID. If not provided, uses the current user.
  ///
  /// Returns true if the user is watching the space, false otherwise
  Future<bool> isWatchingSpace(String spaceId, {String? userId});
  
  /// Get all spaces watched by a user
  ///
  /// [userId] Optional user ID. If not provided, uses the current user.
  ///
  /// Returns a list of spaces being watched by the user
  Future<List<SpaceEntity>> getWatchedSpaces({String? userId});
  
  /// Get count of users watching a space
  ///
  /// [spaceId] The ID of the space
  ///
  /// Returns the number of users watching the space
  Future<int> getWatcherCount(String spaceId);
  
  /// Get all users watching a space
  ///
  /// [spaceId] The ID of the space
  ///
  /// Returns a list of user IDs watching the space
  Future<List<String>> getSpaceWatchers(String spaceId);
  
  /// Get recommendations based on watched spaces
  ///
  /// [userId] Optional user ID. If not provided, uses the current user.
  /// [limit] Maximum number of recommendations to return
  ///
  /// Returns a list of recommended spaces
  Future<List<SpaceEntity>> getWatchlistRecommendations({String? userId, int limit = 5});
  
  /// Stream of watched spaces for a user
  ///
  /// [userId] Optional user ID. If not provided, uses the current user.
  ///
  /// Returns a stream of spaces being watched by the user
  Stream<List<SpaceEntity>> watchWatchedSpaces({String? userId});
  
  /// Get a stream of changes to a specific space's watcher count
  ///
  /// [spaceId] The ID of the space
  ///
  /// Returns a stream of watcher counts
  Stream<int> watchWatcherCount(String spaceId);
} 