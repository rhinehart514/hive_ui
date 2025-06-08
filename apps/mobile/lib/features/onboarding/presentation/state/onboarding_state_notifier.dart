import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/application/services/onboarding_service.dart';
import 'package:hive_ui/domain/entities/user_profile.dart';
import 'package:hive_ui/domain/failures/auth_failure.dart';

/// The possible steps in the onboarding process.
enum OnboardingStep {
  /// Step 1: Enter name.
  name,
  
  /// Step 2: Enter residence.
  residence,
  
  /// Step 3: Enter major.
  major,
  
  /// Step 4: Select interests.
  interests,
  
  /// Step 5: Select role (request verified+).
  role,
  
  /// Onboarding completed successfully.
  completed,
}

/// The possible states of the onboarding process.
enum OnboardingStatus {
  /// The onboarding process is idle.
  idle,
  
  /// The onboarding process is in progress.
  inProgress,
  
  /// The onboarding process has completed successfully.
  completed,
  
  /// The onboarding process has encountered an error.
  error,
}

/// The state for the onboarding process.
class OnboardingState {
  /// The current status of the onboarding process.
  final OnboardingStatus status;
  
  /// The current step in the onboarding process.
  final OnboardingStep currentStep;
  
  /// The user's first name.
  final String firstName;
  
  /// The user's last name.
  final String lastName;
  
  /// The user's email address.
  final String email;
  
  /// The user's residence.
  final String residence;
  
  /// The user's major.
  final String major;
  
  /// The user's selected interests.
  final List<String> interests;
  
  /// Whether the user has requested verified+ status.
  final bool requestVerifiedPlus;
  
  /// The completed user profile, if any.
  final UserProfile? profile;
  
  /// The error that occurred during onboarding, if any.
  final Failure? error;

  /// Creates a new onboarding state.
  const OnboardingState({
    required this.status,
    required this.currentStep,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.residence,
    required this.major,
    required this.interests,
    required this.requestVerifiedPlus,
    this.profile,
    this.error,
  });

  /// The initial state for the onboarding process.
  factory OnboardingState.initial(String email) {
    return OnboardingState(
      status: OnboardingStatus.idle,
      currentStep: OnboardingStep.name,
      firstName: '',
      lastName: '',
      email: email,
      residence: '',
      major: '',
      interests: const [],
      requestVerifiedPlus: false,
    );
  }

  /// Creates a copy of this state with the given fields replaced.
  OnboardingState copyWith({
    OnboardingStatus? status,
    OnboardingStep? currentStep,
    String? firstName,
    String? lastName,
    String? email,
    String? residence,
    String? major,
    List<String>? interests,
    bool? requestVerifiedPlus,
    UserProfile? profile,
    Failure? error,
  }) {
    return OnboardingState(
      status: status ?? this.status,
      currentStep: currentStep ?? this.currentStep,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      residence: residence ?? this.residence,
      major: major ?? this.major,
      interests: interests ?? this.interests,
      requestVerifiedPlus: requestVerifiedPlus ?? this.requestVerifiedPlus,
      profile: profile ?? this.profile,
      error: error ?? this.error,
    );
  }
}

/// Manages the onboarding state and provides methods to interact with it.
class OnboardingStateNotifier extends StateNotifier<OnboardingState> {
  final OnboardingService _onboardingService;

  /// Creates a new onboarding state notifier with the given dependencies.
  OnboardingStateNotifier(this._onboardingService, String email)
      : super(OnboardingState.initial(email));

  /// Sets the user's first and last name.
  void setName(String firstName, String lastName) {
    state = state.copyWith(
      firstName: firstName,
      lastName: lastName,
      currentStep: OnboardingStep.residence,
    );
  }

  /// Sets the user's residence.
  void setResidence(String residence) {
    state = state.copyWith(
      residence: residence,
      currentStep: OnboardingStep.major,
    );
  }

  /// Sets the user's major.
  void setMajor(String major) {
    state = state.copyWith(
      major: major,
      currentStep: OnboardingStep.interests,
    );
  }

  /// Sets the user's interests.
  void setInterests(List<String> interests) {
    state = state.copyWith(
      interests: interests,
      currentStep: OnboardingStep.role,
    );
  }

  /// Sets whether the user has requested verified+ status.
  void setRequestVerifiedPlus(bool requestVerifiedPlus) {
    state = state.copyWith(
      requestVerifiedPlus: requestVerifiedPlus,
    );
  }

  /// Goes back to the previous step in the onboarding process.
  void goBack() {
    final currentStep = state.currentStep;
    OnboardingStep? previousStep;

    switch (currentStep) {
      case OnboardingStep.residence:
        previousStep = OnboardingStep.name;
        break;
      case OnboardingStep.major:
        previousStep = OnboardingStep.residence;
        break;
      case OnboardingStep.interests:
        previousStep = OnboardingStep.major;
        break;
      case OnboardingStep.role:
        previousStep = OnboardingStep.interests;
        break;
      default:
        return;
    }

    state = state.copyWith(
      currentStep: previousStep,
    );
  }

  /// Completes the onboarding process.
  Future<void> completeOnboarding(String uid) async {
    state = state.copyWith(
      status: OnboardingStatus.inProgress,
    );

    final result = await _onboardingService.completeOnboarding(
      uid: uid,
      firstName: state.firstName,
      lastName: state.lastName,
      email: state.email,
      residence: state.residence,
      major: state.major,
      interests: state.interests,
      requestVerifiedPlus: state.requestVerifiedPlus,
    );

    result.fold(
      onSuccess: (profile) {
        state = state.copyWith(
          status: OnboardingStatus.completed,
          currentStep: OnboardingStep.completed,
          profile: profile,
        );
      },
      onFailure: (failure) {
        state = state.copyWith(
          status: OnboardingStatus.error,
          error: failure,
        );
      },
    );
  }

  /// Clears any errors in the current state.
  void clearError() {
    state = state.copyWith(
      status: OnboardingStatus.idle,
      error: null,
    );
  }
} 