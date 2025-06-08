import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';
import 'package:hive_ui/features/auth/domain/repositories/onboarding_repository.dart';

/// Parameters for the [CompleteOnboardingUseCase]
class CompleteOnboardingParams {
  /// The user's onboarding profile
  final OnboardingProfile profile;

  /// Create [CompleteOnboardingParams]
  const CompleteOnboardingParams({required this.profile});
}

/// Use case for completing the onboarding process
class CompleteOnboardingUseCase {
  final OnboardingRepository _repository;
  final FirebaseAuth _auth;

  /// Create a new [CompleteOnboardingUseCase]
  CompleteOnboardingUseCase({
    required OnboardingRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;

  /// Execute the use case
  Future<void> call(CompleteOnboardingParams params) async {
    try {
      // Get the current user ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final userId = currentUser.uid;

      // 1. Save the onboarding profile
      await _repository.saveOnboardingProfile(params.profile);

      // 2. Mark onboarding as completed
      await _repository.markOnboardingComplete(userId);

      debugPrint('Onboarding completed successfully for user: $userId');
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      rethrow;
    }
  }
}
