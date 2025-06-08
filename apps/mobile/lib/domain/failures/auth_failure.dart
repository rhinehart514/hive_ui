/// Base abstract class for all failures in the application.
abstract class Failure {
  /// The user-friendly message describing the failure.
  final String message;

  /// Creates a new failure with the given message.
  const Failure(this.message);

  @override
  String toString() => message;
}

/// Base class for authentication-related failures.
class AuthFailure extends Failure {
  /// Creates a new authentication failure with the given message.
  const AuthFailure(String message) : super(message);
}

/// Failure that occurs when an invalid email is provided.
class InvalidEmailFailure extends AuthFailure {
  /// Creates a new invalid email failure with the given message.
  const InvalidEmailFailure(String message) : super(message);
}

/// Failure that occurs when a magic link has expired.
class ExpiredLinkFailure extends AuthFailure {
  /// Creates a new expired link failure with the given message.
  const ExpiredLinkFailure(String message) : super(message);
}

/// Failure that occurs due to server-side issues.
class ServerFailure extends Failure {
  /// Creates a new server failure with the given message.
  const ServerFailure(String message) : super(message);
}

/// Failure that occurs due to network connectivity issues.
class NetworkFailure extends Failure {
  /// Creates a new network failure with the given message.
  const NetworkFailure(String message) : super(message);
}

/// Failure that occurs when the cause is unknown.
class UnknownFailure extends Failure {
  /// Creates a new unknown failure with the given message.
  const UnknownFailure(String message) : super(message);
} 