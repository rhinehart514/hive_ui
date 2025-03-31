import 'dart:io';

import '../entities/space.dart';
import '../entities/space_entity.dart';

/// Interface for accessing space data
abstract class SpaceRepository {
  /// Create a new space
  Future<bool> createSpace(Space space, {File? coverImage});
  
  /// Get a space by ID
  Future<Space?> getSpaceById(String spaceId);
  
  /// Get spaces for the current user
  Future<List<Space>> getUserSpaces();
  
  /// Get trending spaces
  Future<List<Space>> getTrendingSpaces();
  
  /// Get recommended spaces
  Future<List<Space>> getRecommendedSpaces();
  
  /// Join a space
  Future<bool> joinSpace(String spaceId);
  
  /// Leave a space
  Future<bool> leaveSpace(String spaceId);
  
  /// Update a space
  Future<bool> updateSpace(Space space, {File? coverImage});
  
  /// Delete a space
  Future<bool> deleteSpace(String spaceId);
  
  /// Check if a space name is available
  Future<bool> isSpaceNameAvailable(String name);
  
  /// Search for spaces
  Future<List<Space>> searchSpaces(String query);
  
  /// Get suggested spaces for a user
  Future<List<SpaceEntity>> getSuggestedSpacesForUser({
    required String userId,
    int limit = 5,
  });
} 