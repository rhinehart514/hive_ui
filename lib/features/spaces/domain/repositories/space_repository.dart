import 'dart:io';

import '../entities/space.dart';
import '../entities/space_entity.dart';
import 'package:hive_ui/models/event.dart';

/// Interface for accessing space data
abstract class SpaceRepository {
  /// Create a new space
  Future<bool> createSpace(SpaceEntity space, {File? coverImage});
  
  /// Get a space by ID with optional space type
  Future<SpaceEntity?> getSpaceById(String spaceId, {String? spaceType});
  
  /// Get spaces for the current user
  Future<List<SpaceEntity>> getUserSpaces(String userId);
  
  /// Get spaces where user is invited
  Future<List<SpaceEntity>> getInvitedSpaces(String userId);
  
  /// Get trending spaces (non-private only)
  Future<List<SpaceEntity>> getTrendingSpaces();
  
  /// Get recommended spaces based on user interests
  Future<List<SpaceEntity>> getRecommendedSpaces(String userId);
  
  /// Join a space
  /// Throws [SpaceJoinException] if user has reached limit or isn't invited to private space
  Future<bool> joinSpace(String spaceId, String userId);
  
  /// Leave a space
  Future<bool> leaveSpace(String spaceId, String userId);
  
  /// Update a space
  Future<bool> updateSpace(SpaceEntity space, {File? coverImage});
  
  /// Delete a space
  Future<bool> deleteSpace(String spaceId);
  
  /// Check if a space name is available
  Future<bool> isSpaceNameAvailable(String name);
  
  /// Search for spaces (excludes private spaces)
  Future<List<SpaceEntity>> searchSpaces(String query);
  
  /// Invite users to a private space
  Future<bool> inviteUsers(String spaceId, List<String> userIds);
  
  /// Remove users from invited list
  Future<bool> removeInvites(String spaceId, List<String> userIds);
  
  /// Add admin to space (max 4)
  /// Throws [SpaceAdminLimitException] if limit reached
  Future<bool> addAdmin(String spaceId, String userId);
  
  /// Remove admin from space
  Future<bool> removeAdmin(String spaceId, String userId);
  
  /// Create event in space
  /// Only admins can create events
  Future<bool> createSpaceEvent(String spaceId, String eventId, String creatorId);
  
  /// Get simple engagement metrics for space
  Future<SpaceMetrics> getSpaceMetrics(String spaceId);
  
  /// Get user's interests to match with spaces
  Future<List<String>> getUserInterests(String userId);
  
  /// Update space verification status
  /// Only system admins can verify spaces
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified);
  
  /// Get events associated with a space
  Future<List<Event>> getSpaceEvents(String spaceId);
}

/// Exception thrown when trying to join a space but user has reached limit
class SpaceJoinException implements Exception {
  final String message;
  SpaceJoinException(this.message);
}

/// Exception thrown when trying to add admin but space has reached limit
class SpaceAdminLimitException implements Exception {
  final String message;
  SpaceAdminLimitException(this.message);
}

/// Simple metrics for a space
class SpaceMetrics {
  final int memberCount;
  final int eventCount;
  final int activeMembers; // Members active in last 7 days
  
  const SpaceMetrics({
    required this.memberCount,
    required this.eventCount,
    required this.activeMembers,
  });
} 