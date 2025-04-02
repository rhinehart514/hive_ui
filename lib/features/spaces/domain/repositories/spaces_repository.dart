import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/models/event.dart';

/// Interface defining the contract for the Spaces repository
abstract class SpacesRepository {
  /// Get all spaces
  Future<List<SpaceEntity>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
  });

  /// Get space by ID
  /// 
  /// [id] The ID of the space to retrieve
  /// [spaceType] Optional space type to help locate the space in the correct collection
  Future<SpaceEntity?> getSpaceById(String id, {String? spaceType});

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

  /// Get events associated with a space
  /// 
  /// [spaceId] The ID of the space to get events for
  /// Returns a list of events associated with the space
  Future<List<Event>> getSpaceEvents(String spaceId);
}
