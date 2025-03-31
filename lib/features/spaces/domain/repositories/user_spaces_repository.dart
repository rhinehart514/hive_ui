import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';

/// Repository interface for managing user-space relationships
abstract class UserSpacesRepository {
  /// Gets all spaces joined by a user
  Future<List<SpaceEntity>> getUserSpaces(String userId);
  
  /// Joins a space for a user
  Future<void> joinSpace(String userId, String spaceId);
  
  /// Leaves a space for a user
  Future<void> leaveSpace(String userId, String spaceId);
  
  /// Checks if a user has joined a space
  Future<bool> hasJoinedSpace(String userId, String spaceId);
  
  /// Gets all user IDs who have joined a space
  Future<List<String>> getSpaceMembers(String spaceId);
  
  /// Gets recommended spaces for a user based on their interests and joined spaces
  Future<List<SpaceEntity>> getRecommendedSpaces(String userId);
} 