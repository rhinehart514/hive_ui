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
    required this.createdAt,
    required this.lastSignInTime,
    this.providers = const [],
  });

  /// Creates an empty user for unauthenticated state
  factory AuthUser.empty() => AuthUser(
        id: '',
        email: '',
        isEmailVerified: false,
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
      createdAt: createdAt ?? this.createdAt,
      lastSignInTime: lastSignInTime ?? this.lastSignInTime,
      providers: providers ?? this.providers,
    );
  }
}
