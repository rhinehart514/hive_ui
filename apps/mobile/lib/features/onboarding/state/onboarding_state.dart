import 'package:flutter/foundation.dart';

/// Represents the state of the onboarding profile completion flow.
///
/// This class holds all the data collected during the multi-step profile
/// completion process. It provides an immutable data structure with a copyWith
/// method for updates.
class OnboardingState {
  final String? firstName;
  final String? lastName;
  final String? username;
  final String? year;
  final String? major;
  final String? residenceType;
  final String? specificResidence;
  final List<String> interests;
  final String? accountTier;
  final int currentPageIndex;
  final bool isSubmitting;
  final String? error;

  /// Creates an instance of [OnboardingState].
  const OnboardingState({
    this.firstName,
    this.lastName,
    this.username,
    this.year,
    this.major,
    this.residenceType,
    this.specificResidence,
    this.interests = const [],
    this.accountTier,
    this.currentPageIndex = 0,
    this.isSubmitting = false,
    this.error,
  });

  /// Creates a copy of this state with the specified fields updated.
  OnboardingState copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? year,
    String? major,
    String? residenceType,
    String? specificResidence,
    List<String>? interests,
    String? accountTier,
    int? currentPageIndex,
    bool? isSubmitting,
    String? error,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      year: year ?? this.year,
      major: major ?? this.major,
      residenceType: residenceType ?? this.residenceType,
      specificResidence: specificResidence ?? this.specificResidence,
      interests: interests ?? this.interests,
      accountTier: accountTier ?? this.accountTier,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error ?? this.error,
    );
  }

  /// Checks if the current page data is valid to proceed to the next step.
  bool isCurrentPageValid() {
    final pageToValidate = currentPageIndex;
    debugPrint('OnboardingState: Validating page $pageToValidate of $totalPages');

    // Extra debugging info
    debugPrint('OnboardingState: Current data - firstName: $firstName, lastName: $lastName, username: $username, ' 'year: $year, major: $major, residenceType: $residenceType, interests: ${interests.length} items');

    bool result = false;

    switch (pageToValidate) {
      case 0: // Name page
        // Restore proper validation for first and last name
        result = firstName != null &&
            firstName!.trim().isNotEmpty &&
            lastName != null &&
            lastName!.trim().isNotEmpty;
        debugPrint('OnboardingState: Name page is ${result ? "valid" : "invalid"} with "$firstName $lastName"');
        break;

      case 1: // Year page
        // Restore year validation
        result = year != null;
        debugPrint('OnboardingState: Year page is ${result ? "valid" : "invalid"} (Year: $year)');
        break;

      case 2: // Major page
        // Restore major validation
        result = major != null;
        debugPrint('OnboardingState: Major page is ${result ? "valid" : "invalid"} (Major: $major)');
        break;

      case 3: // Residence page
        // Restore residence validation
        result = residenceType != null;
        debugPrint('OnboardingState: Residence page is ${result ? "valid" : "invalid"} (Residence: $residenceType)');
        break;

      case 4: // Interests page
        // Restore interests validation (e.g., at least 1 interest)
        // You might want a stricter rule like minimum 3 interests
        result = interests.isNotEmpty;
        debugPrint('OnboardingState: Interests page is ${result ? "valid" : "invalid"} (Count: ${interests.length})');
        break;

      case 5: // Account tier page
        debugPrint('OnboardingState: Account tier page is always valid');
        result = true;
        break;

      default:
        debugPrint('OnboardingState: Unrecognized page index: $pageToValidate');
        result = false;
        break;
    }

    debugPrint('OnboardingState: Final validation result for page $pageToValidate: $result');
    return result;
  }

  /// Total number of pages in the onboarding flow.
  static const int totalPages = 6;
} 