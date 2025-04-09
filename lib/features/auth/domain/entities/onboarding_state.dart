import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Represents the state of the onboarding process
@immutable
class OnboardingState {
  /// User's first name
  final String firstName;

  /// User's last name
  final String lastName;

  /// Selected year (Freshman, Sophomore, etc.)
  final String? selectedYear;

  /// Selected field of study
  final String? selectedMajor;

  /// Selected residence
  final String? selectedResidence;

  /// Selected account tier
  final AccountTier selectedTier;

  /// Selected club ID
  final String? selectedClubId;

  /// Selected club role
  final String? selectedClubRole;

  /// List of selected interests
  final List<String> selectedInterests;

  /// Current step in the onboarding process
  final int currentStep;

  /// Total steps in the onboarding process
  final int totalSteps;

  /// Whether the onboarding completion is in progress
  final bool isCompletingOnboarding;

  /// Whether clubs are being loaded
  final bool isLoadingClubs;

  /// List of available clubs
  final List<Club> clubs;

  /// Creates an OnboardingState
  const OnboardingState({
    this.firstName = '',
    this.lastName = '',
    this.selectedYear,
    this.selectedMajor,
    this.selectedResidence,
    this.selectedTier = AccountTier.verified,
    this.selectedClubId,
    this.selectedClubRole,
    this.selectedInterests = const [],
    this.currentStep = 0,
    this.totalSteps = 6,
    this.isCompletingOnboarding = false,
    this.isLoadingClubs = false,
    this.clubs = const [],
  });

  /// Creates a copy of this state with the given fields replaced
  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    String? selectedYear,
    String? selectedMajor,
    String? selectedResidence,
    AccountTier? selectedTier,
    String? selectedClubId,
    String? selectedClubRole,
    List<String>? selectedInterests,
    int? currentStep,
    int? totalSteps,
    bool? isCompletingOnboarding,
    bool? isLoadingClubs,
    List<Club>? clubs,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedMajor: selectedMajor ?? this.selectedMajor,
      selectedResidence: selectedResidence ?? this.selectedResidence,
      selectedTier: selectedTier ?? this.selectedTier,
      selectedClubId: selectedClubId ?? this.selectedClubId,
      selectedClubRole: selectedClubRole ?? this.selectedClubRole,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      isCompletingOnboarding: isCompletingOnboarding ?? this.isCompletingOnboarding,
      isLoadingClubs: isLoadingClubs ?? this.isLoadingClubs,
      clubs: clubs ?? this.clubs,
    );
  }

  /// Full name derived from first and last name
  String get fullName => '$firstName $lastName'.trim();

  /// Whether the user has completed personal info (name and academic details)
  bool get hasCompletedPersonalInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      selectedYear != null &&
      selectedMajor != null &&
      selectedResidence != null;

  /// Whether the user has completed account tier selection
  bool get hasCompletedTierSelection => true; // Always true since we have a default

  /// Whether the user has completed club selection if they're verified plus
  bool get hasCompletedClubSelection =>
      selectedTier != AccountTier.verifiedPlus ||
      (selectedClubId != null && selectedClubRole != null);

  /// Whether the user has selected at least one interest
  bool get hasSelectedInterests => selectedInterests.isNotEmpty;

  /// Whether all required onboarding steps are complete
  bool get isComplete =>
      hasCompletedPersonalInfo &&
      hasCompletedTierSelection &&
      hasCompletedClubSelection &&
      hasSelectedInterests;

  /// Whether the required minimum number of interests has been selected
  bool hasSelectedMinInterests(int minInterests) =>
      selectedInterests.length >= minInterests;

  /// Whether the current step can proceed to the next step
  bool canProceedToNextStep(int currentStepIndex, int minInterests) {
    switch (currentStepIndex) {
      case 0: // Personal info
        return hasCompletedPersonalInfo;
      case 1: // Account tier
        return true; // Always can proceed as tier has a default value
      case 2: // Club selection
        return true; // Optional, can always proceed
      case 3: // Interests
        return hasSelectedMinInterests(minInterests);
      default:
        return true;
    }
  }

  /// Get the selected club from the clubs list
  Club? get selectedClub => selectedClubId != null
      ? clubs.where((club) => club.id == selectedClubId).firstOrNull
      : null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingState &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.selectedYear == selectedYear &&
        other.selectedMajor == selectedMajor &&
        other.selectedResidence == selectedResidence &&
        other.selectedTier == selectedTier &&
        other.selectedClubId == selectedClubId &&
        other.selectedClubRole == selectedClubRole &&
        listEquals(other.selectedInterests, selectedInterests) &&
        other.currentStep == currentStep &&
        other.totalSteps == totalSteps &&
        other.isCompletingOnboarding == isCompletingOnboarding &&
        other.isLoadingClubs == isLoadingClubs &&
        listEquals(other.clubs, clubs);
  }

  @override
  int get hashCode {
    return firstName.hashCode ^
        lastName.hashCode ^
        selectedYear.hashCode ^
        selectedMajor.hashCode ^
        selectedResidence.hashCode ^
        selectedTier.hashCode ^
        selectedClubId.hashCode ^
        selectedClubRole.hashCode ^
        selectedInterests.hashCode ^
        currentStep.hashCode ^
        totalSteps.hashCode ^
        isCompletingOnboarding.hashCode ^
        isLoadingClubs.hashCode ^
        clubs.hashCode;
  }
}
