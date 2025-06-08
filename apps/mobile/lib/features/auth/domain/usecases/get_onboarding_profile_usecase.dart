import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';
import 'package:hive_ui/features/auth/domain/repositories/onboarding_repository.dart';

/// Use case for retrieving the onboarding profile
class GetOnboardingProfileUseCase {
  final OnboardingRepository _repository;

  /// Create a new [GetOnboardingProfileUseCase]
  GetOnboardingProfileUseCase({
    required OnboardingRepository repository,
  }) : _repository = repository;

  /// Execute the use case
  Future<OnboardingProfile?> call() async {
    try {
      return await _repository.getOnboardingProfile();
    } catch (e) {
      debugPrint('Error getting onboarding profile: $e');
      return null;
    }
  }
}
