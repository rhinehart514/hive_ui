import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';
import 'package:hive_ui/features/auth/domain/usecases/complete_onboarding_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/get_onboarding_profile_usecase.dart';
import 'package:hive_ui/features/auth/domain/usecases/update_onboarding_progress_usecase.dart';
import 'package:hive_ui/models/club.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:hive_ui/services/service_initializer.dart';

/// Represents the state of the onboarding process
class OnboardingState {
  /// Current step in the onboarding process
  final int currentStep;

  /// Total number of steps
  final int totalSteps;

  /// First name entered by the user
  final String firstName;

  /// Last name entered by the user
  final String lastName;

  /// Selected academic year
  final String? selectedYear;

  /// Selected field/major
  final String? selectedField;

  /// Selected residence
  final String? selectedResidence;

  /// Selected account tier
  final AccountTier selectedTier;

  /// ID of the selected club
  final String? selectedClubId;

  /// Role in the selected club
  final String? selectedClubRole;

  /// Selected interests
  final List<String> selectedInterests;

  /// Whether the onboarding completion is in progress
  final bool isCompletingOnboarding;

  /// Whether clubs are being loaded
  final bool isLoadingClubs;

  /// List of available clubs
  final List<Club> clubs;

  /// Creates an OnboardingState
  const OnboardingState({
    this.currentStep = 0,
    this.totalSteps = 5,
    this.firstName = '',
    this.lastName = '',
    this.selectedYear,
    this.selectedField,
    this.selectedResidence,
    this.selectedTier = AccountTier.verified,
    this.selectedClubId,
    this.selectedClubRole,
    this.selectedInterests = const [],
    this.isCompletingOnboarding = false,
    this.isLoadingClubs = false,
    this.clubs = const [],
  });

  /// Creates a copy of this OnboardingState with the given fields replaced with new values
  OnboardingState copyWith({
    int? currentStep,
    int? totalSteps,
    String? firstName,
    String? lastName,
    String? selectedYear,
    String? selectedField,
    String? selectedResidence,
    AccountTier? selectedTier,
    String? selectedClubId,
    String? selectedClubRole,
    List<String>? selectedInterests,
    bool? isCompletingOnboarding,
    bool? isLoadingClubs,
    List<Club>? clubs,
  }) {
    return OnboardingState(
      currentStep: currentStep ?? this.currentStep,
      totalSteps: totalSteps ?? this.totalSteps,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      selectedYear: selectedYear ?? this.selectedYear,
      selectedField: selectedField ?? this.selectedField,
      selectedResidence: selectedResidence ?? this.selectedResidence,
      selectedTier: selectedTier ?? this.selectedTier,
      selectedClubId: selectedClubId ?? this.selectedClubId,
      selectedClubRole: selectedClubRole ?? this.selectedClubRole,
      selectedInterests: selectedInterests ?? this.selectedInterests,
      isCompletingOnboarding:
          isCompletingOnboarding ?? this.isCompletingOnboarding,
      isLoadingClubs: isLoadingClubs ?? this.isLoadingClubs,
      clubs: clubs ?? this.clubs,
    );
  }

  /// The user's full name
  String get fullName => '$firstName $lastName'.trim();

  /// Whether the user has completed personal info
  bool get hasCompletedPersonalInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      selectedYear != null &&
      selectedField != null &&
      selectedResidence != null;

  /// Whether the onboarding can proceed to the next step
  bool canProceedToNextStep(int minInterests) {
    switch (currentStep) {
      case 0: // Personal info
        return hasCompletedPersonalInfo;
      case 1: // Account tier
        return true; // Always can proceed as tier has a default value
      case 2: // Club selection (optional)
        return true; // Can always proceed as club selection is optional
      case 3: // Interests
        return selectedInterests.length >= minInterests;
      default:
        return true;
    }
  }

  /// Get the selected club from the clubs list
  Club? get selectedClub => selectedClubId != null
      ? clubs.where((club) => club.id == selectedClubId).firstOrNull
      : null;

  /// Convert to OnboardingProfile domain entity
  OnboardingProfile toOnboardingProfile() {
    return OnboardingProfile(
      firstName: firstName,
      lastName: lastName,
      year: selectedYear,
      field: selectedField,
      residence: selectedResidence,
      accountTier: selectedTier,
      clubId: selectedClubId,
      clubRole: selectedClubRole,
      interests: selectedInterests,
    );
  }
}

/// Controller for managing the onboarding process
class OnboardingController extends StateNotifier<OnboardingState> {
  final GetOnboardingProfileUseCase _getOnboardingProfileUseCase;
  final UpdateOnboardingProgressUseCase _updateOnboardingProgressUseCase;
  final CompleteOnboardingUseCase _completeOnboardingUseCase;

  /// Create a new [OnboardingController]
  OnboardingController({
    required GetOnboardingProfileUseCase getOnboardingProfileUseCase,
    required UpdateOnboardingProgressUseCase updateOnboardingProgressUseCase,
    required CompleteOnboardingUseCase completeOnboardingUseCase,
  })  : _getOnboardingProfileUseCase = getOnboardingProfileUseCase,
        _updateOnboardingProgressUseCase = updateOnboardingProgressUseCase,
        _completeOnboardingUseCase = completeOnboardingUseCase,
        super(const OnboardingState()) {
    // Load clubs and initial data
    _initialize();
  }

  /// Initialize the controller
  Future<void> _initialize() async {
    await _loadClubs();
    await _loadProfile();
  }

  /// Load clubs from the service
  Future<void> _loadClubs() async {
    state = state.copyWith(isLoadingClubs: true);

    try {
      // Try to use optimized service first
      try {
        await ServiceInitializer.initializeServices();

        // First try to get clubs from cached data without network request
        final cachedClubs = OptimizedClubAdapter.getCachedClubs();
        if (cachedClubs.isNotEmpty) {
          debugPrint('Using ${cachedClubs.length} clubs from optimized cache');
          state = state.copyWith(
            clubs: cachedClubs,
            isLoadingClubs: false,
          );
          return;
        }

        // If cache is empty, fetch from network
        final clubs = await OptimizedClubAdapter.getAllClubs();
        state = state.copyWith(
          clubs: clubs,
          isLoadingClubs: false,
        );
      } catch (optimizedError) {
        debugPrint('Error loading clubs: $optimizedError');
        state = state.copyWith(isLoadingClubs: false);
      }
    } catch (e) {
      debugPrint('Failed to load clubs: $e');
      state = state.copyWith(isLoadingClubs: false);
    }
  }

  /// Load saved profile data if available
  Future<void> _loadProfile() async {
    try {
      final profile = await _getOnboardingProfileUseCase();
      if (profile != null) {
        state = state.copyWith(
          firstName: profile.firstName,
          lastName: profile.lastName,
          selectedYear: profile.year,
          selectedField: profile.field,
          selectedResidence: profile.residence,
          selectedTier: profile.accountTier,
          selectedClubId: profile.clubId,
          selectedClubRole: profile.clubRole,
          selectedInterests: profile.interests,
        );
      }
    } catch (e) {
      debugPrint('Error loading profile: $e');
    }
  }

  /// Update the first name
  void updateFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
    _saveProgress();
  }

  /// Update the last name
  void updateLastName(String lastName) {
    state = state.copyWith(lastName: lastName);
    _saveProgress();
  }

  /// Update the selected year
  void updateSelectedYear(String? year) {
    state = state.copyWith(selectedYear: year);
    _saveProgress();
  }

  /// Update the selected field
  void updateSelectedField(String? field) {
    state = state.copyWith(selectedField: field);
    _saveProgress();
  }

  /// Update the selected residence
  void updateSelectedResidence(String? residence) {
    state = state.copyWith(selectedResidence: residence);
    _saveProgress();
  }

  /// Update the selected account tier
  void updateSelectedTier(AccountTier tier) {
    state = state.copyWith(selectedTier: tier);
    _saveProgress();
  }

  /// Update the selected club
  void updateSelectedClub(String? clubId) {
    state = state.copyWith(selectedClubId: clubId);
    _saveProgress();
  }

  /// Update the selected club role
  void updateSelectedClubRole(String? role) {
    state = state.copyWith(selectedClubRole: role);
    _saveProgress();
  }

  /// Update the selected interests
  void updateSelectedInterests(List<String> interests) {
    state = state.copyWith(selectedInterests: interests);
    _saveProgress();
  }

  /// Add an interest to the selected interests
  void addInterest(String interest) {
    if (!state.selectedInterests.contains(interest)) {
      state = state.copyWith(
        selectedInterests: [...state.selectedInterests, interest],
      );
      _saveProgress();
    }
  }

  /// Remove an interest from the selected interests
  void removeInterest(String interest) {
    state = state.copyWith(
      selectedInterests:
          state.selectedInterests.where((i) => i != interest).toList(),
    );
    _saveProgress();
  }

  /// Go to the next step
  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
      _saveProgress();
    }
  }

  /// Go to the previous step
  void previousStep() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  /// Go to a specific step
  void goToStep(int step) {
    if (step >= 0 && step < state.totalSteps) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Save the current progress
  Future<void> _saveProgress() async {
    try {
      final progressData = {
        'step': state.currentStep,
        'firstName': state.firstName,
        'lastName': state.lastName,
        'selectedYear': state.selectedYear,
        'selectedField': state.selectedField,
        'selectedResidence': state.selectedResidence,
        'selectedTier': state.selectedTier.toString().split('.').last,
        'selectedClubId': state.selectedClubId,
        'selectedClubRole': state.selectedClubRole,
        'selectedInterests': state.selectedInterests,
      };

      await _updateOnboardingProgressUseCase(
        UpdateOnboardingProgressParams(progressData: progressData),
      );
    } catch (e) {
      debugPrint('Error saving progress: $e');
    }
  }

  /// Complete the onboarding process
  Future<void> completeOnboarding() async {
    if (state.isCompletingOnboarding) return;

    state = state.copyWith(isCompletingOnboarding: true);

    try {
      final profile = state.toOnboardingProfile();

      await _completeOnboardingUseCase(
        CompleteOnboardingParams(profile: profile),
      );

      state = state.copyWith(isCompletingOnboarding: false);
    } catch (e) {
      debugPrint('Error completing onboarding: $e');
      state = state.copyWith(isCompletingOnboarding: false);
      rethrow;
    }
  }
}
