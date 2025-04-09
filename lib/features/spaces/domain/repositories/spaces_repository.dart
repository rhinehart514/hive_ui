import 'dart:io';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_member_entity.dart';

/// Exception thrown when a user has reached their limit of joined spaces
class SpaceJoinException implements Exception {
  final String message;
  SpaceJoinException(this.message);
  @override
  String toString() => 'SpaceJoinException: $message';
}

/// Exception thrown when a user tries to add too many admins to a space
class SpaceAdminLimitException implements Exception {
  final String message;
  SpaceAdminLimitException(this.message);
  @override
  String toString() => 'SpaceAdminLimitException: $message';
}

/// Interface defining the contract for the Spaces repository
/// This is the main repository for space-related operations
abstract class SpacesRepository {
  /// Get all spaces
  /// 
  /// [forceRefresh] Whether to force a refresh from the data source
  /// [includePrivate] Whether to include private spaces in the results
  /// [includeJoined] Whether to include spaces the current user has joined
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
  /// 
  /// If [userId] is provided, gets spaces joined by that user instead
  Future<List<SpaceEntity>> getJoinedSpaces({String? userId});

  /// Get spaces where user is invited
  Future<List<SpaceEntity>> getInvitedSpaces({String? userId});

  /// Get recommended spaces for the current user
  /// 
  /// If [userId] is provided, gets recommendations for that user
  Future<List<SpaceEntity>> getRecommendedSpaces({String? userId});

  /// Search spaces by query text
  Future<List<SpaceEntity>> searchSpaces(String query);

  /// Join a space
  /// 
  /// [spaceId] The ID of the space to join
  /// [userId] Optional user ID to join on behalf of. If not provided, uses the current user.
  /// 
  /// Returns true if successful, false otherwise.
  /// May throw [SpaceJoinException] if user has reached limit or isn't invited to private space
  Future<bool> joinSpace(String spaceId, {String? userId});

  /// Leave a space
  /// 
  /// [spaceId] The ID of the space to leave
  /// [userId] Optional user ID to leave on behalf of. If not provided, uses the current user.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> leaveSpace(String spaceId, {String? userId});

  /// Check if a user has joined a space
  /// 
  /// [spaceId] The ID of the space to check
  /// [userId] Optional user ID to check. If not provided, uses the current user.
  /// 
  /// Returns true if the user has joined the space, false otherwise.
  Future<bool> hasJoinedSpace(String spaceId, {String? userId});

  /// Get spaces with upcoming events
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents();

  /// Get trending spaces
  Future<List<SpaceEntity>> getTrendingSpaces();

  /// Create a new space
  /// 
  /// [name] The name of the space
  /// [description] The description of the space
  /// [iconCodePoint] The icon code point for the space
  /// [spaceType] The type of space
  /// [tags] Tags for the space
  /// [isPrivate] Whether the space is private
  /// [creatorId] The ID of the creator
  /// [isHiveExclusive] Whether the space is exclusive to Hive
  /// [coverImage] Optional cover image file for the space
  /// [lastActivityAt] Optional initial activity timestamp
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
    required bool isHiveExclusive,
    File? coverImage,
    DateTime? lastActivityAt,
  });
  
  /// Update an existing space
  /// 
  /// [space] The updated space entity
  /// 
  /// Returns the updated space entity
  Future<SpaceEntity> updateSpace(SpaceEntity space);

  /// Add or update a space's banner image
  /// 
  /// [spaceId] The ID of the space
  /// [bannerImage] The banner image file
  /// 
  /// Returns the URL of the uploaded banner
  Future<String> uploadBannerImage(String spaceId, File bannerImage);

  /// Add or update a space's profile image
  /// 
  /// [spaceId] The ID of the space
  /// [profileImage] The profile image file
  /// 
  /// Returns the URL of the uploaded profile image
  Future<String> uploadProfileImage(String spaceId, File profileImage);

  /// Get events for a space
  /// 
  /// [spaceId] The ID of the space
  /// 
  /// Returns a list of events for the space
  Future<List<Event>> getSpaceEvents(String spaceId);

  /// Check if a space name is already taken
  /// 
  /// [name] The name to check
  /// 
  /// Returns true if the name is already taken, false otherwise
  Future<bool> isSpaceNameTaken(String name);

  /// Add a moderator to a space
  /// 
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to add as a moderator
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> addModerator(String spaceId, String userId);

  /// Remove a moderator from a space
  /// 
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to remove as a moderator
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> removeModerator(String spaceId, String userId);

  /// Add an admin to a space
  /// 
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to add as an admin
  /// 
  /// Returns true if successful, false otherwise
  /// May throw [SpaceAdminLimitException] if max admin limit reached
  Future<bool> addAdmin(String spaceId, String userId);

  /// Remove an admin from a space
  /// 
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to remove as an admin
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> removeAdmin(String spaceId, String userId);

  /// Get all user IDs who have joined a space
  /// 
  /// Returns a list of user IDs
  Future<List<String>> getSpaceMembers(String spaceId);

  /// Get all members of a space with full member details
  /// 
  /// [spaceId] The ID of the space
  /// 
  /// Returns a list of SpaceMemberEntity objects
  Future<List<SpaceMemberEntity>> getSpaceMembersWithDetails(String spaceId);

  /// Get details for a specific member within a space
  /// 
  /// [spaceId] The ID of the space
  /// [memberId] The ID of the member to retrieve
  /// 
  /// Returns the member entity or null if not found
  Future<SpaceMemberEntity?> getSpaceMember(String spaceId, String memberId);
  
  /// Update a space's lifecycle state
  /// 
  /// [spaceId] The ID of the space
  /// [lifecycleState] The new lifecycle state
  /// [lastActivityAt] Optional timestamp of last activity
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> updateLifecycleState(
    String spaceId,
    SpaceLifecycleState lifecycleState, {
    DateTime? lastActivityAt,
  });
  
  /// Update a space's claim status
  /// 
  /// [spaceId] The ID of the space
  /// [claimStatus] The new claim status
  /// [claimId] Optional ID of the associated claim
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> updateClaimStatus(
    String spaceId,
    SpaceClaimStatus claimStatus, {
    String? claimId,
  });

  /// Invite users to a private space
  /// 
  /// [spaceId] The ID of the space to invite to
  /// [userIds] The IDs of the users to invite
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> inviteUsers(String spaceId, List<String> userIds);

  /// Remove users from invited list
  /// 
  /// [spaceId] The ID of the space
  /// [userIds] The IDs of the users to remove from invites
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> removeInvites(String spaceId, List<String> userIds);

  /// Updates the last activity timestamp for a space.
  /// Should be called when significant actions occur (e.g., event created, post made).
  /// 
  /// [spaceId] The ID of the space to update.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> updateSpaceActivity(String spaceId);

  /// Request to join a private space.
  /// 
  /// [spaceId] The ID of the private space.
  /// [userId] The ID of the user requesting to join.
  /// 
  /// Throws exception if space is not private or user already requested/is member.
  Future<void> requestToJoinSpace(String spaceId, String userId);

  /// Get pending join requests for a private space (for Admins/Creators).
  /// 
  /// [spaceId] The ID of the space.
  /// 
  /// Returns a list of user IDs with pending requests.
  Future<List<String>> getJoinRequests(String spaceId);

  /// Approve a join request for a private space (by Admins/Creators).
  /// 
  /// [spaceId] The ID of the space.
  /// [userIdToApprove] The ID of the user whose request is being approved.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> approveJoinRequest(String spaceId, String userIdToApprove);

  /// Deny a join request for a private space (by Admins/Creators).
  /// 
  /// [spaceId] The ID of the space.
  /// [userIdToDeny] The ID of the user whose request is being denied.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> denyJoinRequest(String spaceId, String userIdToDeny);

  /// Initiate the process to archive a space (by Admins/Creators).
  /// Checks if the space is Hive Exclusive.
  /// 
  /// [spaceId] The ID of the space.
  /// [initiatorId] The ID of the admin/creator initiating the archive.
  /// 
  /// Throws Exception if space is not Hive Exclusive or already archived/voting.
  /// Returns true if successful, false otherwise.
  Future<bool> initiateSpaceArchive(String spaceId, String initiatorId);

  /// Cast a vote to archive or reject archiving a space (by Admins/Creators).
  /// Checks if majority approval is reached and finalizes if so.
  /// 
  /// [spaceId] The ID of the space.
  /// [voterId] The ID of the admin/creator voting.
  /// [approve] True to approve archiving, false to reject.
  /// 
  /// Returns the current archive state ('voting', 'archived', 'rejected', 'none').
  /// Throws Exception if voting is not active or voter is not admin/creator.
  Future<String> voteForSpaceArchive(String spaceId, String voterId, bool approve);

  /// Get the current archive status and votes for a space.
  /// 
  /// [spaceId] The ID of the space.
  /// 
  /// Returns a map containing status (e.g., 'voting') and votes ({voterId: bool}).
  Future<Map<String, dynamic>> getSpaceArchiveStatus(String spaceId);

  /// Get spaces marked as featured.
  /// Sorted potentially by lastActivityAt or name.
  Future<List<SpaceEntity>> getFeaturedSpaces({int limit = 20});

  /// Get newest spaces sorted by creation date.
  Future<List<SpaceEntity>> getNewestSpaces({int limit = 20});

  /// Get simple engagement metrics for space
  /// 
  /// [spaceId] The ID of the space to get metrics for
  Future<SpaceMetrics> getSpaceMetrics(String spaceId);

  /// Update space verification status
  /// Only system admins can verify spaces
  /// 
  /// [spaceId] The ID of the space to update
  /// [isVerified] Whether the space is verified
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> updateSpaceVerification(String spaceId, bool isVerified);

  /// Creates a chat for a space's message board
  /// 
  /// [spaceId] The ID of the space
  /// [spaceName] The name of the space
  /// [imageUrl] Optional image URL for the chat
  /// 
  /// Returns the chat ID if successful
  Future<String?> createSpaceChat(String spaceId, String spaceName, {String? imageUrl});
  
  /// Gets the chat ID for a space's message board
  /// 
  /// [spaceId] The ID of the space
  /// 
  /// Returns the chat ID if it exists, null otherwise
  Future<String?> getSpaceChatId(String spaceId);

  /// Submit a leadership claim for a space
  /// 
  /// [spaceId] The ID of the space to claim leadership for
  /// [userId] The ID of the user claiming leadership
  /// [userName] The display name of the user
  /// [email] The email of the user
  /// [reason] The reason for claiming leadership
  /// [credentials] The credentials of the user (role, position, etc.)
  /// 
  /// Returns true if the claim was submitted successfully, false otherwise.
  Future<bool> submitLeadershipClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String reason,
    required String credentials,
  });

  /// Update a space member's role
  /// 
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to update
  /// [role] The new role to assign to the user
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> updateSpaceMemberRole(
    String spaceId,
    String userId,
    String role,
  );
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
