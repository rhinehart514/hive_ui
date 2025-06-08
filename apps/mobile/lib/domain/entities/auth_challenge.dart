import 'package:equatable/equatable.dart';

/// Enum representing the status of an authentication challenge.
enum AuthChallengeStatus {
  /// The challenge is still pending verification.
  pending,

  /// The challenge has been successfully verified.
  verified,

  /// The challenge has expired.
  expired,
}

/// Entity representing an authentication challenge using a magic link.
class AuthChallenge extends Equatable {
  /// The email address the challenge was sent to.
  final String email;

  /// The status of the challenge.
  final AuthChallengeStatus status;

  /// When the challenge was created.
  final DateTime createdAt;

  /// When the challenge expires.
  final DateTime expiresAt;

  /// Duration for which a challenge is valid, in minutes.
  static const int expiryDurationMinutes = 15;

  /// Creates a new AuthChallenge with the given fields.
  const AuthChallenge({
    required this.email,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Creates a new pending challenge for the given email.
  factory AuthChallenge.create(String email) {
    final now = DateTime.now();
    return AuthChallenge(
      email: email,
      status: AuthChallengeStatus.pending,
      createdAt: now,
      expiresAt: now.add(const Duration(minutes: expiryDurationMinutes)),
    );
  }

  /// Returns a copy of this challenge with the given fields replaced.
  AuthChallenge copyWith({
    String? email,
    AuthChallengeStatus? status,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return AuthChallenge(
      email: email ?? this.email,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// Marks the challenge as verified.
  AuthChallenge markAsVerified() {
    return copyWith(status: AuthChallengeStatus.verified);
  }

  /// Marks the challenge as expired.
  AuthChallenge markAsExpired() {
    return copyWith(status: AuthChallengeStatus.expired);
  }

  /// Checks if the challenge has expired.
  bool isExpired() {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Returns the remaining time until expiry in seconds.
  int getRemainingSeconds() {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) {
      return 0;
    }
    return expiresAt.difference(now).inSeconds;
  }

  /// Returns a value object representation of this challenge for storage.
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
    };
  }

  /// Creates an AuthChallenge from a JSON object.
  factory AuthChallenge.fromJson(Map<String, dynamic> json) {
    return AuthChallenge(
      email: json['email'] as String,
      status: AuthChallengeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => AuthChallengeStatus.pending,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(json['expiresAt'] as int),
    );
  }

  @override
  List<Object> get props => [email, status, createdAt, expiresAt];
} 