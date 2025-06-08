import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/auth/domain/repositories/onboarding_repository.dart';

/// Parameters for [UpdateOnboardingProgressUseCase]
class UpdateOnboardingProgressParams {
  /// The progress data to save
  final Map<String, dynamic> progressData;

  /// Create a new [UpdateOnboardingProgressParams]
  const UpdateOnboardingProgressParams({
    required this.progressData,
  });
}

/// Use case for updating onboarding progress
class UpdateOnboardingProgressUseCase {
  final OnboardingRepository _repository;
  final FirebaseAuth _auth;

  /// Create a new [UpdateOnboardingProgressUseCase]
  UpdateOnboardingProgressUseCase({
    required OnboardingRepository repository,
    FirebaseAuth? auth,
  })  : _repository = repository,
        _auth = auth ?? FirebaseAuth.instance;

  /// Execute the use case
  Future<void> call(UpdateOnboardingProgressParams params) async {
    try {
      // Get the current user ID
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      final userId = currentUser.uid;

      // Update the progress
      await _repository.updateOnboardingProgress(userId, params.progressData);

      debugPrint('Onboarding progress updated for user: $userId');
    } catch (e) {
      debugPrint('Error updating onboarding progress: $e');
      rethrow;
    }
  }
}
