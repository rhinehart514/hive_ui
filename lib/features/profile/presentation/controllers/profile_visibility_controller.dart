import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';
import 'package:hive_ui/features/profile/domain/usecases/check_profile_feature_visibility.dart';
import 'package:hive_ui/features/profile/domain/usecases/get_profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/usecases/update_profile_visibility_settings.dart';

/// Controller for managing profile visibility settings
class ProfileVisibilityController extends ChangeNotifier {
  /// Use case for getting visibility settings
  final GetProfileVisibilitySettings _getSettings;
  
  /// Use case for updating visibility settings 
  final UpdateProfileVisibilitySettings _updateSettings;
  
  /// Use case for checking feature visibility
  final CheckProfileFeatureVisibility _checkFeatureVisibility;
  
  /// Current visibility settings
  ProfileVisibilitySettings? _settings;
  
  /// Loading state 
  bool _isLoading = false;
  
  /// Error state
  String? _error;

  /// Constructor
  ProfileVisibilityController({
    required GetProfileVisibilitySettings getSettings,
    required UpdateProfileVisibilitySettings updateSettings,
    required CheckProfileFeatureVisibility checkFeatureVisibility,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings,
        _checkFeatureVisibility = checkFeatureVisibility;

  /// Get the current profile visibility settings
  ProfileVisibilitySettings? get settings => _settings;
  
  /// Check if data is loading
  bool get isLoading => _isLoading;
  
  /// Get error message if any
  String? get error => _error;

  /// Fetch visibility settings for a user
  Future<void> loadSettings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _settings = await _getSettings(userId);
      _error = null;
    } catch (e) {
      _error = 'Failed to load visibility settings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a particular setting
  Future<void> updateSetting({
    required String field,
    required dynamic value,
  }) async {
    if (_settings == null) {
      _error = 'No settings loaded';
      notifyListeners();
      return;
    }
    
    _isLoading = true;
    notifyListeners();
    
    try {
      var updatedSettings = _settings!;
      
      switch (field) {
        case 'isDiscoverable':
          updatedSettings = updatedSettings.copyWith(
            isDiscoverable: value as bool,
            updatedAt: DateTime.now(),
          );
          break;
        case 'showEventsToPublic':
          updatedSettings = updatedSettings.copyWith(
            showEventsToPublic: value as bool,
            updatedAt: DateTime.now(),
          );
          break;
        case 'showSpacesToPublic':
          updatedSettings = updatedSettings.copyWith(
            showSpacesToPublic: value as bool,
            updatedAt: DateTime.now(),
          );
          break;
        case 'showFriendsToPublic':
          updatedSettings = updatedSettings.copyWith(
            showFriendsToPublic: value as bool,
            updatedAt: DateTime.now(),
          );
          break;
        case 'friendRequestsPrivacy':
          updatedSettings = updatedSettings.copyWith(
            friendRequestsPrivacy: value as PrivacyLevel,
            updatedAt: DateTime.now(),
          );
          break;
        case 'activityFeedPrivacy':
          updatedSettings = updatedSettings.copyWith(
            activityFeedPrivacy: value as PrivacyLevel,
            updatedAt: DateTime.now(),
          );
          break;
      }
      
      await _updateSettings(updatedSettings);
      _settings = updatedSettings;
      
    } catch (e) {
      _error = 'Failed to update setting: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a profile feature is visible to another user
  Future<bool> isFeatureVisibleTo({
    required String profileId,
    required String viewerId,
    required ProfileFeature feature,
  }) async {
    try {
      return await _checkFeatureVisibility(
        profileId: profileId,
        viewerId: viewerId,
        feature: feature,
      );
    } catch (e) {
      _error = 'Failed to check feature visibility: $e';
      notifyListeners();
      return false;
    }
  }
} 