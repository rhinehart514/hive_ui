import 'package:hive_ui/features/profile/data/datasources/profile_visibility_remote_datasource.dart';
import 'package:hive_ui/features/profile/data/models/profile_visibility_settings_model.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';

/// Implementation of [ProfileVisibilityRepository]
class ProfileVisibilityRepositoryImpl implements ProfileVisibilityRepository {
  /// Data source for remote operations
  final ProfileVisibilityRemoteDataSource _remoteDataSource;

  /// Constructor
  ProfileVisibilityRepositoryImpl(this._remoteDataSource);

  @override
  Future<ProfileVisibilitySettings> getVisibilitySettings(String userId) async {
    return await _remoteDataSource.getVisibilitySettings(userId);
  }

  @override
  Future<void> updateVisibilitySettings(ProfileVisibilitySettings settings) async {
    final model = ProfileVisibilitySettingsModel.fromEntity(settings);
    await _remoteDataSource.updateVisibilitySettings(model);
  }

  @override
  Future<bool> isProfileVisibleTo(String profileId, String viewerId) async {
    // If it's the same user, they can always view their own profile
    if (profileId == viewerId) {
      return true;
    }

    final settings = await _remoteDataSource.getVisibilitySettings(profileId);
    
    // Check if users are friends when needed for privacy decisions
    final areFriends = await _remoteDataSource.areFriends(profileId, viewerId);
    
    // If profile is not discoverable and they aren't friends, hide it
    if (!settings.isDiscoverable && !areFriends) {
      return false;
    }
    
    return true;
  }

  @override
  Future<bool> isFeatureVisibleTo(
    String profileId,
    String viewerId,
    ProfileFeature feature,
  ) async {
    // If it's the same user, they can always view their own features
    if (profileId == viewerId) {
      return true;
    }
    
    final settings = await _remoteDataSource.getVisibilitySettings(profileId);
    final areFriends = await _remoteDataSource.areFriends(profileId, viewerId);
    
    switch (feature) {
      case ProfileFeature.profile:
        return await isProfileVisibleTo(profileId, viewerId);
        
      case ProfileFeature.events:
        return settings.showEventsToPublic || areFriends;
        
      case ProfileFeature.spaces:
        return settings.showSpacesToPublic || areFriends;
        
      case ProfileFeature.friends:
        return settings.showFriendsToPublic || areFriends;
        
      case ProfileFeature.activityFeed:
        switch (settings.activityFeedPrivacy) {
          case PrivacyLevel.everyone:
            return true;
          case PrivacyLevel.friends:
            return areFriends;
          case PrivacyLevel.private:
            return false;
        }
    }
  }
} 