import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/auth/domain/entities/onboarding_state.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:hive_ui/services/club_service.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';
import 'package:hive_ui/services/service_initializer.dart';
import 'package:hive_ui/services/user_preferences_service.dart';
import 'package:flutter/material.dart';

/// Provider for the onboarding controller
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
  return OnboardingController(
    UserPreferencesService.initialize,
  );
});

/// Controller for managing onboarding state
class OnboardingController extends StateNotifier<OnboardingState> {
  final Future<void> Function() _initializePreferences;

  OnboardingController(this._initializePreferences)
      : super(const OnboardingState()) {
    // Load clubs when the controller is created
    _loadClubs();
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
        debugPrint(
            'Error using optimized service: $optimizedError, falling back to standard service');

        // Fall back to ClubService if optimized service fails
        final clubs = ClubService.getAllClubs();
        state = state.copyWith(
          clubs: clubs,
          isLoadingClubs: false,
        );
      }
    } catch (e) {
      // Handle error
      debugPrint('Failed to load clubs: $e');
      state = state.copyWith(isLoadingClubs: false);
    }
  }

  /// Update the user's first name
  void updateFirstName(String firstName) {
    state = state.copyWith(firstName: firstName);
  }

  /// Update the user's last name
  void updateLastName(String lastName) {
    state = state.copyWith(lastName: lastName);
  }

  /// Update the selected year
  void updateSelectedYear(String? year) {
    state = state.copyWith(selectedYear: year);
  }

  /// Update the selected field of study
  void updateSelectedField(String? field) {
    state = state.copyWith(selectedField: field);
  }

  /// Update the selected residence
  void updateSelectedResidence(String? residence) {
    state = state.copyWith(selectedResidence: residence);
  }

  /// Update the selected account tier
  void updateSelectedTier(AccountTier tier) {
    state = state.copyWith(selectedTier: tier);
  }

  /// Update the selected club
  void updateSelectedClub(String? clubId) {
    state = state.copyWith(selectedClubId: clubId);
  }

  /// Update the selected club role
  void updateSelectedClubRole(String? role) {
    state = state.copyWith(selectedClubRole: role);
  }

  /// Update the selected interests
  void updateSelectedInterests(List<String> interests) {
    state = state.copyWith(selectedInterests: interests);
  }

  /// Move to the next step
  void nextStep() {
    if (state.currentStep < state.totalSteps - 1) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  /// Move to the previous step
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

  /// Complete the onboarding process
  Future<void> completeOnboarding() async {
    if (state.isCompletingOnboarding) return;

    state = state.copyWith(isCompletingOnboarding: true);

    try {
      // Ensure preferences service is initialized
      await _initializePreferences();

      // Create user profile from onboarding data
      final userProfile = UserProfile(
        id: DateTime.now()
            .toString(), // This will be replaced by a real ID when Firebase is integrated
        username: state.fullName,
        displayName: state.fullName,
        year: state.selectedYear ?? 'Unknown',
        major: state.selectedField ?? 'Undecided',
        residence: state.selectedResidence ?? 'Unknown',
        eventCount: 0,
        clubCount: state.selectedClubId != null ? 1 : 0,
        friendCount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        accountTier: state.selectedTier,
        interests: state.selectedInterests,
      );

      // Store profile in preferences
      await UserPreferencesService.storeProfile(userProfile);

      // Mark onboarding as completed
      await UserPreferencesService.setOnboardingCompleted(true);

      state = state.copyWith(isCompletingOnboarding: false);
    } catch (e) {
      // Handle error
      state = state.copyWith(isCompletingOnboarding: false);
      rethrow;
    }
  }
}
