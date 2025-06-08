
import 'package:hive_ui/features/spaces/data/models/space_model.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';
import 'package:hive_ui/models/event.dart' as event_model;

/// Abstract definition of a data source for spaces
abstract class SpacesDataSource {
  /// Get all spaces from the data source
  Future<List<SpaceModel>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
    String? userId,
  });

  /// Get a space by ID
  Future<SpaceModel?> getSpaceById(String id, {String? spaceType});

  /// Get spaces by category
  Future<List<SpaceModel>> getSpacesByCategory(String category);

  /// Get all spaces joined by a user
  Future<List<SpaceModel>> getJoinedSpaces({String? userId});

  /// Get recommended spaces for a user
  Future<List<SpaceModel>> getRecommendedSpaces({String? userId});

  /// Search spaces by query text
  Future<List<SpaceModel>> searchSpaces(String query);

  /// Join a space
  Future<void> joinSpace(String spaceId, {String? userId});

  /// Leave a space
  Future<void> leaveSpace(String spaceId, {String? userId});

  /// Check if a user has joined a space
  Future<bool> hasJoinedSpace(String spaceId, {String? userId});

  /// Get spaces with upcoming events
  Future<List<SpaceModel>> getSpacesWithUpcomingEvents();

  /// Get trending spaces
  Future<List<SpaceModel>> getTrendingSpaces();

  /// Create a new space
  Future<SpaceModel> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    required bool isHiveExclusive,
  });

  /// Check if a space name is already taken
  Future<bool> isSpaceNameTaken(String name);

  /// Get events for a space
  /// 
  /// [spaceId] The ID of the space
  /// [limit] Maximum number of events to return
  /// 
  /// Returns a list of events for the space
  Future<List<event_model.Event>> getSpaceEvents(String spaceId, {int limit = 10});

  /// Get the chat ID associated with a space
  /// Returns null if no chat exists for this space
  Future<String?> getSpaceChatId(String spaceId);
  
  /// Get details for a specific space member
  /// Returns null if the member is not found
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId);
} 