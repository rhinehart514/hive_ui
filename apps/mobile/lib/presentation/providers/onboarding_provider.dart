import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/onboarding/presentation/state/onboarding_state_notifier.dart';
import 'package:hive_ui/features/auth/di/providers.dart';
import 'package:hive_ui/features/auth/presentation/state/auth_state_notifier.dart';

// Re-export for convenience
export 'package:hive_ui/features/onboarding/presentation/state/onboarding_state_notifier.dart';

/// Provider for the onboarding state
/// This is a wrapper around the onboardingStateNotifierProvider.family that:
/// 1. Gets the email from the auth state
/// 2. Creates a non-family provider for easier consumption
final onboardingProvider = StateNotifierProvider<OnboardingStateNotifier, OnboardingState>((ref) {
  final authState = ref.watch(authStateNotifierProvider);
  
  // Get the email from auth state if authenticated, otherwise empty string
  final email = authState.status == AuthStatus.authenticated && authState.email != null
      ? authState.email!
      : '';
  
  // Use the existing family provider with the email
  return ref.watch(onboardingStateNotifierProvider(email).notifier);
});

/// Provider for the current step in the onboarding process
final currentOnboardingStepProvider = Provider<OnboardingStep>((ref) {
  return ref.watch(onboardingProvider).currentStep;
});

/// Provider for the progress percentage in the onboarding process
final onboardingProgressProvider = Provider<double>((ref) {
  final step = ref.watch(currentOnboardingStepProvider);
  
  // Calculate progress percentage based on current step
  switch (step) {
    case OnboardingStep.name:
      return 0.2; // 20% (1/5)
    case OnboardingStep.residence:
      return 0.4; // 40% (2/5)
    case OnboardingStep.major:
      return 0.6; // 60% (3/5)
    case OnboardingStep.interests:
      return 0.8; // 80% (4/5)
    case OnboardingStep.role:
    case OnboardingStep.completed:
      return 1.0; // 100% (5/5 or completed)
    default:
      return 0.0;
  }
});

/// Provider that determines if the current step is valid and the user can proceed
final isCurrentStepValidProvider = Provider<bool>((ref) {
  final state = ref.watch(onboardingProvider);
  final step = state.currentStep;
  
  // Validate current step based on required fields
  switch (step) {
    case OnboardingStep.name:
      return state.firstName.isNotEmpty && state.lastName.isNotEmpty;
    case OnboardingStep.residence:
      return state.residence.isNotEmpty;
    case OnboardingStep.major:
      return state.major.isNotEmpty;
    case OnboardingStep.interests:
      return state.interests.isNotEmpty;
    case OnboardingStep.role:
      return true; // Always valid as requestVerifiedPlus is optional
    default:
      return false;
  }
}); 