import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Interface defining the contract for the Spaces repository
abstract class SpacesRepository {
  /// Get all spaces
  Future<List<SpaceEntity>> getAllSpaces({bool forceRefresh = false});

  /// Get space by ID
  Future<SpaceEntity?> getSpaceById(String id);

  /// Get spaces by category or type
  Future<List<SpaceEntity>> getSpacesByCategory(String category);

  /// Get all spaces joined by the current user
  Future<List<SpaceEntity>> getJoinedSpaces();

  /// Get recommended spaces for the current user
  Future<List<SpaceEntity>> getRecommendedSpaces();

  /// Search spaces by query text
  Future<List<SpaceEntity>> searchSpaces(String query);

  /// Join a space
  Future<void> joinSpace(String spaceId);

  /// Leave a space
  Future<void> leaveSpace(String spaceId);

  /// Check if the current user has joined a space
  Future<bool> hasJoinedSpace(String spaceId);

  /// Get spaces with upcoming events
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents();

  /// Get trending spaces
  Future<List<SpaceEntity>> getTrendingSpaces();

  /// Create a new space
  /// 
  /// Returns the created space entity
  Future<SpaceEntity> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    bool isHiveExclusive = true,
  });

  /// Check if a space name is already taken
  /// 
  /// Returns true if the name is taken, false otherwise
  Future<bool> isSpaceNameTaken(String name);
}
