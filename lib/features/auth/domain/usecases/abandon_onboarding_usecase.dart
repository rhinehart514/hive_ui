import 'package:hive_ui/features/auth/domain/repositories/auth_repository.dart';
import 'package:hive_ui/core/usecases/usecase.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:flutter/foundation.dart';

/// UseCase for abandoning the onboarding process
class AbandonOnboardingUseCase implements NoParamsUseCase<void> {
  final AuthRepository _authRepository;

  /// Creates an AbandonOnboardingUseCase instance
  AbandonOnboardingUseCase(this._authRepository);

  /// Execute the onboarding abandonment operation
  @override
  Future<void> call() async {
    try {
      // Clear user preferences first
      await UserPreferencesService.clearUserData();

      // Then sign out from Firebase
      await _authRepository.signOut();

      debugPrint(
          'User abandoned onboarding - auth state and user data cleared');
    } catch (e) {
      debugPrint('Error during onboarding abandonment: $e');
      // Don't rethrow - we want to fail silently if possible when abandoning
    }
  }
}
