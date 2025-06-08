import 'package:equatable/equatable.dart';

/// Enum representing the user's tier level.
enum UserTier {
  /// Base user with standard access.
  base,

  /// Verified+ user with additional privileges, pending approval.
  pending,

  /// Fully verified user with additional privileges.
  verified_plus,
}

/// Entity representing a user's profile information.
class UserProfile extends Equatable {
  /// The user's first name.
  final String firstName;

  /// The user's last name.
  final String lastName;

  /// The user's email address.
  final String email;

  /// The user's generated username.
  final String username;

  /// The user's campus residence.
  final String residence;

  /// The user's major or area of study.
  final String major;

  /// The user's selected interests.
  final List<String> interests;

  /// The user's tier level.
  final UserTier tier;

  /// Creates a new UserProfile with the given fields.
  const UserProfile({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.username,
    required this.residence,
    required this.major,
    required this.interests,
    required this.tier,
  });

  /// Returns a copy of this profile with the given fields replaced.
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? username,
    String? residence,
    String? major,
    List<String>? interests,
    UserTier? tier,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      username: username ?? this.username,
      residence: residence ?? this.residence,
      major: major ?? this.major,
      interests: interests ?? this.interests,
      tier: tier ?? this.tier,
    );
  }

  /// Converts this profile to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'username': username,
      'residence': residence,
      'major': major,
      'interests': interests,
      'tier': tier.toString().split('.').last,
    };
  }

  /// Creates a UserProfile from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      residence: json['residence'] as String,
      major: json['major'] as String,
      interests: List<String>.from(json['interests'] as List),
      tier: _userTierFromString(json['tier'] as String),
    );
  }

  /// Maps a string to a UserTier enum value.
  static UserTier _userTierFromString(String tierString) {
    switch (tierString) {
      case 'base':
        return UserTier.base;
      case 'pending':
        return UserTier.pending;
      case 'verified_plus':
        return UserTier.verified_plus;
      default:
        return UserTier.base;
    }
  }

  /// Validates this profile to ensure all fields are properly set.
  bool isValid() {
    return firstName.isNotEmpty &&
        lastName.isNotEmpty &&
        email.isNotEmpty &&
        username.isNotEmpty &&
        residence.isNotEmpty &&
        major.isNotEmpty &&
        interests.isNotEmpty &&
        interests.length <= 10;
  }

  /// Returns the user's full name (first + last).
  String get fullName => '$firstName $lastName';

  @override
  List<Object> get props => [
        firstName,
        lastName,
        email,
        username,
        residence,
        major,
        interests,
        tier,
      ];
} 