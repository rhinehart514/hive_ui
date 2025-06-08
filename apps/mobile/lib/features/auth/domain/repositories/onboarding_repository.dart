import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';

/// Repository interface for onboarding operations
abstract class OnboardingRepository {
  /// Saves the onboarding profile
  Future<void> saveOnboardingProfile(OnboardingProfile profile);

  /// Retrieves the onboarding profile
  Future<OnboardingProfile?> getOnboardingProfile();

  /// Updates the user's onboarding progress
  Future<void> updateOnboardingProgress(
      String userId, Map<String, dynamic> progressData);

  /// Retrieves the saved onboarding progress
  Future<Map<String, dynamic>?> getOnboardingProgress();

  /// Marks the onboarding process as completed
  Future<void> markOnboardingComplete(String userId);

  /// Checks if the user has completed onboarding
  bool hasCompletedOnboarding();

  /// Resets the onboarding process
  Future<void> resetOnboarding();
}
