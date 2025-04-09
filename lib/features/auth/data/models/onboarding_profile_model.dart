import 'package:hive_ui/features/auth/domain/entities/onboarding_profile.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Data model for onboarding profile
class OnboardingProfileModel {
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

  /// Creates a new OnboardingProfileModel
  OnboardingProfileModel({
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

  /// Creates a model from a domain entity
  factory OnboardingProfileModel.fromDomain(OnboardingProfile profile) {
    return OnboardingProfileModel(
      firstName: profile.firstName,
      lastName: profile.lastName,
      year: profile.year,
      major: profile.major,
      residence: profile.residence,
      accountTier: profile.accountTier,
      clubId: profile.clubId,
      clubRole: profile.clubRole,
      interests: List<String>.from(profile.interests),
      onboardingCompleted: profile.onboardingCompleted,
    );
  }

  /// Converts this model to a domain entity
  OnboardingProfile toDomain() {
    return OnboardingProfile(
      firstName: firstName,
      lastName: lastName,
      year: year,
      major: major,
      residence: residence,
      accountTier: accountTier,
      clubId: clubId,
      clubRole: clubRole,
      interests: interests,
      onboardingCompleted: onboardingCompleted,
    );
  }

  /// Creates a model from a JSON map
  factory OnboardingProfileModel.fromJson(Map<String, dynamic> json) {
    return OnboardingProfileModel(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      year: json['year'] as String?,
      major: json['major'] as String?,
      residence: json['residence'] as String?,
      accountTier: _parseAccountTier(json['accountTier']),
      clubId: json['clubId'] as String?,
      clubRole: json['clubRole'] as String?,
      interests: List<String>.from(json['interests'] ?? []),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
    );
  }

  /// Converts this model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'year': year,
      'major': major,
      'residence': residence,
      'accountTier': accountTier.toString().split('.').last,
      'clubId': clubId,
      'clubRole': clubRole,
      'interests': interests,
      'displayName': '$firstName $lastName'.trim(),
      'onboardingCompleted': onboardingCompleted,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Parses the account tier string to enum
  static AccountTier _parseAccountTier(dynamic tier) {
    if (tier == null) return AccountTier.public;

    if (tier is int) {
      return AccountTier.values[tier];
    }

    if (tier is String) {
      try {
        return AccountTier.values.firstWhere(
          (e) => e.toString().split('.').last.toLowerCase() == tier.toLowerCase(),
          orElse: () => AccountTier.public,
        );
      } catch (_) {
        return AccountTier.public;
      }
    }

    return AccountTier.public;
  }
}
