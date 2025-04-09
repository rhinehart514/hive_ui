import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';

/// Repository interface for managing profile visibility settings
abstract class ProfileVisibilityRepository {
  /// Get visibility settings for a user
  Future<ProfileVisibilitySettings> getVisibilitySettings(String userId);
  
  /// Update visibility settings for a user
  Future<void> updateVisibilitySettings(ProfileVisibilitySettings settings);
  
  /// Check if a user's profile is visible to another user
  Future<bool> isProfileVisibleTo(String profileId, String viewerId);
  
  /// Check if a specific profile feature is visible to another user
  /// 
  /// [profileId] is the ID of the profile being viewed
  /// [viewerId] is the ID of the user trying to view
  /// [feature] is the profile feature to check visibility for
  Future<bool> isFeatureVisibleTo(
    String profileId, 
    String viewerId, 
    ProfileFeature feature,
  );
}

/// Enum representing different profile features with visibility controls
enum ProfileFeature {
  /// The entire profile
  profile,
  
  /// User's events
  events,
  
  /// User's spaces
  spaces,
  
  /// User's friends list
  friends,
  
  /// User's activity feed
  activityFeed,
} 