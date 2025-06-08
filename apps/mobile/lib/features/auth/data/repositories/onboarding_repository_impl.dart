import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/data/datasources/onboarding_local_datasource.dart';
import 'package:hive_ui/features/auth/data/datasources/onboarding_remote_datasource.dart';
import 'package:hive_ui/features/auth/data/models/onboarding_profile_model.dart';
import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';
import 'package:hive_ui/features/auth/domain/repositories/onboarding_repository.dart';

/// Implementation of [OnboardingRepository] that coordinates between local and remote data sources
class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource _localDataSource;
  final OnboardingRemoteDataSource _remoteDataSource;

  /// Create a new [OnboardingRepositoryImpl]
  OnboardingRepositoryImpl({
    required OnboardingLocalDataSource localDataSource,
    required OnboardingRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  @override
  Future<void> saveOnboardingProfile(OnboardingProfile profile) async {
    try {
      // Save to local storage first
      final model = OnboardingProfileModel.fromDomain(profile);
      await _localDataSource.saveOnboardingProfile(model);

      // Then save to remote if user is authenticated
      try {
        await _remoteDataSource.saveOnboardingProfile(model);
      } catch (e) {
        // Log but don't fail if remote save fails
        debugPrint('Warning: Failed to save profile to remote: $e');
      }
    } catch (e) {
      debugPrint('Error saving onboarding profile: $e');
      rethrow;
    }
  }

  @override
  Future<OnboardingProfile?> getOnboardingProfile() async {
    try {
      final profileModel = await _localDataSource.getOnboardingProfile();
      return profileModel?.toDomain();
    } catch (e) {
      debugPrint('Error getting onboarding profile: $e');
      return null;
    }
  }

  @override
  Future<void> updateOnboardingProgress(
      String userId, Map<String, dynamic> progressData) async {
    try {
      // Save progress locally
      await _localDataSource.saveOnboardingProgress(progressData);

      // Update remotely if possible
      try {
        await _remoteDataSource.updateOnboardingProgress(userId, progressData);
      } catch (e) {
        // Log but don't fail if remote update fails
        debugPrint('Warning: Failed to update progress remotely: $e');
      }
    } catch (e) {
      debugPrint('Error updating onboarding progress: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getOnboardingProgress() async {
    try {
      return await _localDataSource.getOnboardingProgress();
    } catch (e) {
      debugPrint('Error getting onboarding progress: $e');
      return null;
    }
  }

  @override
  Future<void> markOnboardingComplete(String userId) async {
    try {
      // Mark as completed locally
      await _localDataSource.markOnboardingCompleted(true);

      // Update remotely if possible
      try {
        await _remoteDataSource.markOnboardingComplete(userId);
      } catch (e) {
        // Log but don't fail if remote update fails
        debugPrint('Warning: Failed to mark onboarding complete remotely: $e');
      }
    } catch (e) {
      debugPrint('Error marking onboarding as complete: $e');
      rethrow;
    }
  }

  @override
  bool hasCompletedOnboarding() {
    return _localDataSource.hasCompletedOnboarding();
  }

  @override
  Future<void> resetOnboarding() async {
    try {
      await _localDataSource.clearOnboardingData();
    } catch (e) {
      debugPrint('Error resetting onboarding: $e');
      rethrow;
    }
  }
}
