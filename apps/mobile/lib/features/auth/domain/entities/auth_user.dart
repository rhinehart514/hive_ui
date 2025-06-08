import 'package:flutter/foundation.dart';

/// Represents the authenticated user in the system
/// This entity is designed to contain minimal user authentication information
@immutable
class AuthUser {
  /// Unique identifier for the user
  final String id;

  /// User's email address
  final String email;

  /// User's display name
  final String? displayName;

  /// URL to the user's profile picture
  final String? photoUrl;

  /// Whether the user's email is verified
  final bool isEmailVerified;

  /// Whether the user is verified (level 1)
  final bool isVerified;
  
  /// Whether the user has Verified+ status (level 2)
  final bool isVerifiedPlus;
  
  /// The user's verification level (0=none, 1=verified, 2=verified+)
  final int verificationLevel;

  /// Account creation timestamp
  final DateTime createdAt;

  /// Last sign-in timestamp
  final DateTime lastSignInTime;

  /// List of authentication providers the user has connected
  final List<String> providers;

  /// Creates an AuthUser instance
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.isEmailVerified,
    this.isVerified = false,
    this.isVerifiedPlus = false,
    this.verificationLevel = 0,
    required this.createdAt,
    required this.lastSignInTime,
    this.providers = const [],
  });

  /// Creates an empty user for unauthenticated state
  factory AuthUser.empty() => AuthUser(
        id: '',
        email: '',
        isEmailVerified: false,
        isVerified: false,
        isVerifiedPlus: false,
        verificationLevel: 0,
        createdAt: DateTime.now(),
        lastSignInTime: DateTime.now(),
      );

  /// Check if this is an empty (unauthenticated) user
  bool get isEmpty => id.isEmpty;

  /// Check if this is an authenticated user
  bool get isNotEmpty => !isEmpty;

  /// Returns true if the user is connected with the specified provider
  bool hasProvider(String providerId) => providers.contains(providerId);
  
  /// Returns true if the user has multiple authentication methods
  bool get hasMultipleProviders => providers.length > 1;

  /// Creates a copy of this user with the given fields replaced with new values
  AuthUser copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
    bool? isVerified,
    bool? isVerifiedPlus,
    int? verificationLevel,
    DateTime? createdAt,
    DateTime? lastSignInTime,
    List<String>? providers,
  }) {
    return AuthUser(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      isVerified: isVerified ?? this.isVerified,
      isVerifiedPlus: isVerifiedPlus ?? this.isVerifiedPlus,
      verificationLevel: verificationLevel ?? this.verificationLevel,
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      providers: providers ?? this.providers,
    );
  }
}
