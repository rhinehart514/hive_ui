import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'onboarding_state.dart';
import 'package:flutter/foundation.dart';

/// A state notifier that manages the [OnboardingState] and provides methods
/// to update the state during the onboarding flow.
class OnboardingStateNotifier extends StateNotifier<OnboardingState> {
  OnboardingStateNotifier() : super(const OnboardingState());

  /// Updates the user's first and last name.
  void updateName(String firstName, String lastName) {
    // Trim both inputs to ensure no whitespace issues
    final trimmedFirstName = firstName.trim();
    final trimmedLastName = lastName.trim();
    
    // Log the update operation for debugging
    debugPrint('OnboardingStateNotifier: Updating name to "$trimmedFirstName $trimmedLastName"');
    
    // Update the state with the trimmed values
    state = state.copyWith(
      firstName: trimmedFirstName,
      lastName: trimmedLastName,
    );
    
    // Check if the update was successful
    final updated = state.firstName == trimmedFirstName && state.lastName == trimmedLastName;
    debugPrint('OnboardingStateNotifier: Name update ${updated ? "successful" : "failed"}');
    debugPrint('OnboardingStateNotifier: Current page valid: ${state.isCurrentPageValid()}');
  }

  /// Updates the user's username.
  ///
  /// Trims whitespace and validates format before updating.
  void updateUsername(String username) {
    // Trim input to ensure no whitespace issues
    final trimmedUsername = username.trim();
    
    // Log the update operation for debugging
    debugPrint('OnboardingStateNotifier: Updating username to "$trimmedUsername"');
    
    // Update the state with the trimmed value
    state = state.copyWith(username: trimmedUsername);
    
    // Check if the update was successful
    final updated = state.username == trimmedUsername;
    debugPrint('OnboardingStateNotifier: Username update ${updated ? "successful" : "failed"}');
    debugPrint('OnboardingStateNotifier: Current page valid: ${state.isCurrentPageValid()}');
    
    _provideTactileFeedback();
  }

  /// Checks if a username is unique in the system.
  ///
  /// This is a placeholder for the actual implementation that would
  /// make a server request to check username availability.
  /// Returns true if the username is available, false otherwise.
  Future<bool> isUsernameUnique(String username) async {
    // Placeholder for actual implementation
    // This would typically involve a server call to check uniqueness
    // For now, we'll simulate network delay and return true for most usernames
    await Future.delayed(const Duration(milliseconds: 500));
    
    // List of already taken usernames for testing
    final takenUsernames = ['admin', 'test', 'user', 'username', 'hive'];
    
    return !takenUsernames.contains(username.toLowerCase());
  }

  /// Updates the user's academic year.
  void updateYear(String year) {
    state = state.copyWith(year: year);
    _provideTactileFeedback();
  }

  /// Updates the user's major/field of study.
  void updateMajor(String major) {
    state = state.copyWith(major: major);
  }

  /// Updates the user's residence type and specific residence if applicable.
  void updateResidence(String residenceType, {String? specificResidence}) {
    state = state.copyWith(
      residenceType: residenceType,
      specificResidence: specificResidence,
    );
    _provideTactileFeedback();
  }

  /// Adds an interest to the list if not already present.
  void addInterest(String interest) {
    if (!state.interests.contains(interest) && state.interests.length < 10) {
      state = state.copyWith(
        interests: [...state.interests, interest],
      );
      _provideTactileFeedback();
    }
  }

  /// Removes an interest from the list.
  void removeInterest(String interest) {
    state = state.copyWith(
      interests: state.interests.where((i) => i != interest).toList(),
    );
    _provideTactileFeedback();
  }

  /// Sets the account tier based on email domain verification.
  void setAccountTier(String tier) {
    state = state.copyWith(accountTier: tier);
  }

  /// Navigates to the next page if the current page is valid.
  /// If forceNavigation is true, it will navigate regardless of validation.
  bool goToNextPage({bool forceNavigation = false}) {
    // Read state *inside* the method to ensure it's current
    final currentState = state;
    final currentPageIsValid = forceNavigation ? true : currentState.isCurrentPageValid();
    debugPrint('OnboardingStateNotifier: goToNextPage called. Current index: ${currentState.currentPageIndex}, Is valid: $currentPageIsValid, Force: $forceNavigation');
    
    if (!currentPageIsValid) {
      debugPrint('OnboardingStateNotifier: Blocking navigation - current page is invalid based on internal check. Page index: ${currentState.currentPageIndex}');
      // Provide haptic feedback to indicate invalid action
      HapticFeedback.mediumImpact();
      return false;
    }

    if (currentState.currentPageIndex < OnboardingState.totalPages - 1) {
      final nextPageIndex = currentState.currentPageIndex + 1;
      debugPrint('OnboardingStateNotifier: Proceeding to update state for page index $nextPageIndex');
      
      // Update state
      try {
        state = currentState.copyWith(currentPageIndex: nextPageIndex);
        // Provide haptic feedback for successful navigation
        HapticFeedback.mediumImpact();
        // Verify state *after* update
        debugPrint('OnboardingStateNotifier: State updated. New index: ${state.currentPageIndex}');
        return true;
      } catch (e) {
        debugPrint('OnboardingStateNotifier: Error updating page index: $e');
        return false;
      }
    }
    
    debugPrint('OnboardingStateNotifier: Already on the last page (${currentState.currentPageIndex}). Cannot go forward.');
    return false;
  }

  /// Navigates to the previous page if possible.
  bool goToPreviousPage() {
    if (state.currentPageIndex > 0) {
      state = state.copyWith(currentPageIndex: state.currentPageIndex - 1);
      _provideTactileFeedback();
      return true;
    }
    return false;
  }

  /// Navigates to a specific page by index.
  void goToPage(int index) {
    if (index >= 0 && index < OnboardingState.totalPages) {
      state = state.copyWith(currentPageIndex: index);
      _provideTactileFeedback();
    }
  }

  /// Sets the submitting state to show loading indicators.
  void setSubmitting(bool isSubmitting) {
    state = state.copyWith(isSubmitting: isSubmitting);
  }

  /// Sets an error message.
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// Provides haptic feedback for page transitions and selections.
  void _provideTactileFeedback() {
    HapticFeedback.mediumImpact();
  }
} 