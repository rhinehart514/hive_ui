import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/data/models/onboarding_profile_model.dart';
import 'package:hive_ui/services/user_preferences_service.dart';

/// Interface for local onboarding data operations
abstract class OnboardingLocalDataSource {
  /// Saves the onboarding profile data to local storage
  Future<bool> saveOnboardingProfile(OnboardingProfileModel profile);

  /// Retrieves the onboarding profile from local storage
  Future<OnboardingProfileModel?> getOnboardingProfile();

  /// Saves the onboarding progress data
  Future<bool> saveOnboardingProgress(Map<String, dynamic> progressData);

  /// Retrieves the saved onboarding progress data
  Future<Map<String, dynamic>?> getOnboardingProgress();

  /// Marks onboarding as completed in local storage
  Future<bool> markOnboardingCompleted(bool completed);

  /// Checks if the user has completed onboarding
  bool hasCompletedOnboarding();

  /// Clears all onboarding data from local storage
  Future<bool> clearOnboardingData();
}

/// Implementation of [OnboardingLocalDataSource] using shared preferences
class SharedPreferencesOnboardingDataSource
    implements OnboardingLocalDataSource {
  static const String _profileKey = 'onboarding_profile';

  @override
  Future<bool> saveOnboardingProfile(OnboardingProfileModel profile) async {
    try {
      // Convert profile to user profile and store it
      final userProfile = profile.toDomain().toUserProfile('temp_id');
      final success = await UserPreferencesService.storeProfile(userProfile);

      debugPrint('Saved onboarding profile to local storage: $success');
      return success;
    } catch (e) {
      debugPrint('Error saving onboarding profile to local storage: $e');
      return false;
    }
  }

  @override
  Future<OnboardingProfileModel?> getOnboardingProfile() async {
    try {
      // Get the stored profile and convert it to onboarding profile
      final userProfile = await UserPreferencesService.getStoredProfile();
      if (userProfile == null) {
        return null;
      }

      // Convert UserProfile to OnboardingProfileModel
      return OnboardingProfileModel(
        firstName: userProfile.displayName.split(' ').first,
        lastName: userProfile.displayName.split(' ').skip(1).join(' '),
        year: userProfile.year,
        major: userProfile.major,
        residence: userProfile.residence,
        accountTier: userProfile.accountTier,
        interests: userProfile.interests ?? [],
      );
    } catch (e) {
      debugPrint('Error retrieving onboarding profile from local storage: $e');
      return null;
    }
  }

  @override
  Future<bool> saveOnboardingProgress(Map<String, dynamic> progressData) async {
    return await UserPreferencesService.setOnboardingData(progressData);
  }

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress() async {
    return await UserPreferencesService.getOnboardingData();
  }

  @override
  Future<bool> markOnboardingCompleted(bool completed) async {
    return await UserPreferencesService.setOnboardingCompleted(completed);
  }

  @override
  bool hasCompletedOnboarding() {
    return UserPreferencesService.hasCompletedOnboarding();
  }

  @override
  Future<bool> clearOnboardingData() async {
    try {
      // Clear all onboarding data
      await UserPreferencesService.clearOnboardingData();

      return true;
    } catch (e) {
      debugPrint('Error clearing onboarding data: $e');
      return false;
    }
  }
}
