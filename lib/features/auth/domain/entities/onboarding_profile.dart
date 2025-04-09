import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Domain entity representing a user's onboarding profile
@immutable
class OnboardingProfile {
  /// User's first name
  final String firstName;

  /// User's last name
  final String lastName;

  /// Selected academic year
  final String? year;

  /// Selected field of study/major
  final String? major;

  /// Selected residence
  final String? residence;

  /// Selected account tier
  final AccountTier accountTier;

  /// ID of the selected club/organization
  final String? clubId;

  /// Role in the selected club
  final String? clubRole;

  /// List of selected interests
  final List<String> interests;

  /// Whether onboarding is complete
  final bool onboardingCompleted;

  /// Creates a new OnboardingProfile
  const OnboardingProfile({
    required this.firstName,
    required this.lastName,
    this.year,
    this.major,
    this.residence,
    required this.accountTier,
    this.clubId,
    this.clubRole,
    required this.interests,
    this.onboardingCompleted = false,
  });

  /// Creates a copy of this OnboardingProfile with the given fields replaced with new values
  OnboardingProfile copyWith({
    String? firstName,
    String? lastName,
    String? year,
    String? major,
    String? residence,
    AccountTier? accountTier,
    String? clubId,
    String? clubRole,
    List<String>? interests,
    bool? onboardingCompleted,
  }) {
    return OnboardingProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      year: year ?? this.year,
      major: major ?? this.major,
      residence: residence ?? this.residence,
      accountTier: accountTier ?? this.accountTier,
      clubId: clubId ?? this.clubId,
      clubRole: clubRole ?? this.clubRole,
      interests: interests ?? this.interests,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Full name derived from first and last name
  String get fullName => '$firstName $lastName'.trim();

  /// Whether the user has completed personal info (name and academic details)
  bool get hasCompletedPersonalInfo =>
      firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      year != null &&
      major != null &&
      residence != null;

  /// Whether the required minimum number of interests has been selected
  bool hasSelectedMinInterests(int minInterests) =>
      interests.length >= minInterests;

  /// Converts this profile to a UserProfile model
  UserProfile toUserProfile(String userId) {
    return UserProfile(
      id: userId,
      username: fullName.toLowerCase().replaceAll(' ', '_'),
      displayName: fullName,
      year: year ?? 'Unknown',
      major: major ?? 'Undecided',
      residence: residence ?? 'Unknown',
      eventCount: 0,
      spaceCount: clubId != null ? 1 : 0,
      friendCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      accountTier: accountTier,
      interests: interests,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OnboardingProfile &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.year == year &&
        other.major == major &&
        other.residence == residence &&
        other.accountTier == accountTier &&
        other.clubId == clubId &&
        other.clubRole == clubRole &&
        listEquals(other.interests, interests) &&
        other.onboardingCompleted == onboardingCompleted;
  }

  @override
  int get hashCode {
    return firstName.hashCode ^
        lastName.hashCode ^
        year.hashCode ^
        major.hashCode ^
        residence.hashCode ^
        accountTier.hashCode ^
        clubId.hashCode ^
        clubRole.hashCode ^
        interests.hashCode ^
        onboardingCompleted.hashCode;
  }
}
