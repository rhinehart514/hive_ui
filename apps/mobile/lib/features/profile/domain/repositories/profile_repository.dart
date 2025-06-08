import 'dart:io';
// import 'package:hive_ui/models/user_profile.dart'; // Old import
import '../entities/user_profile.dart'; // Corrected import
import 'package:hive_ui/models/event.dart'; // Might need adjustment
import 'package:hive_ui/models/space.dart'; // Might need adjustment
import '../entities/profile_analytics.dart';
import '../entities/user_search_filters.dart';
import '../entities/recommended_user.dart';

/// Repository for accessing and managing user profiles
abstract class ProfileRepository {
  /// Get a user profile by ID (or current user if ID is not provided)
  Future<UserProfile?> getProfile([String? userId]);

  /// Update a user profile
  Future<void> updateProfile(UserProfile profile);

  /// Create a new user profile
  Future<void> createProfile(UserProfile profile);

  /// Upload a profile image and return the URL
  Future<String> uploadProfileImage(File imageFile);

  /// Remove the profile image
  Future<void> removeProfileImage();

  /// Stream to watch profile updates in real-time
  Stream<UserProfile?> watchProfile(String userId);

  /// Update only the interests field for a user
  /// This is optimized for updating just the interests array
  Future<void> updateUserInterests(String userId, List<String> interests);
  
  /// Save an event to the user's saved events list
  Future<void> saveEvent(String userId, Event event);
  
  /// Remove an event from the user's saved events list
  Future<void> removeEvent(String userId, String eventId);
  
  /// Get all saved events for a user
  Future<List<Event>> getSavedEvents(String userId);
  
  /// Check if an event is saved by the user
  Future<bool> isEventSaved(String userId, String eventId);
  
  /// Get spaces joined by a user
  Future<List<Space>> getJoinedSpaces(String userId);

  /// Get analytics data for a user profile
  Future<ProfileAnalytics?> getProfileAnalytics(String userId);

  /// Record an interaction event on a profile (e.g., view)
  /// [viewedUserId] The ID of the profile that was viewed.
  /// [viewerId] The ID of the user who performed the view.
  /// [interactionType] A string identifier for the type of interaction (e.g., 'profile_view').
  Future<void> recordProfileInteraction({
    required String viewedUserId,
    required String viewerId,
    required String interactionType, // Consider using an enum for better type safety
  });

  /// Search for user profiles based on query and filters
  Future<List<UserProfile>> searchProfiles({
    required String query,
    UserSearchFilters? filters, // Defined in entities/user_search_filters.dart
    int limit = 20,
  });

  /// Get recommended users to connect with
  Future<List<RecommendedUser>> getRecommendedUsers({
    String? basedOnUserId, // Optional: Get recommendations for a specific user
    int limit = 10,
  });

  /// Update a user's restriction status
  Future<void> updateUserRestriction(String userId, {
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    String? restrictedBy,
  });
}
