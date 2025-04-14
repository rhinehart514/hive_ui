import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final dynamic details;

  const Failure({
    required this.message,
    this.code,
    this.details,
  });

  @override
  List<Object?> get props => [message, code, details];
}

/// Failure when a community policy operation fails
class CommunityPolicyFailure extends Failure {
  const CommunityPolicyFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when policy validation fails
class PolicyValidationFailure extends Failure {
  const PolicyValidationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when policy version is not found
class PolicyVersionNotFoundFailure extends Failure {
  const PolicyVersionNotFoundFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when user has not accepted the policy
class PolicyNotAcceptedFailure extends Failure {
  const PolicyNotAcceptedFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when content violates policy
class PolicyViolationFailure extends Failure {
  const PolicyViolationFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when policy operation is unauthorized
class PolicyUnauthorizedFailure extends Failure {
  const PolicyUnauthorizedFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when there's a server error during policy operations
class PolicyServerFailure extends Failure {
  const PolicyServerFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when there's a network error during policy operations
class PolicyNetworkFailure extends Failure {
  const PolicyNetworkFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
}

/// Failure when there's a cache error during policy operations
class PolicyCacheFailure extends Failure {
  const PolicyCacheFailure({
    required String message,
    String? code,
    dynamic details,
  }) : super(message: message, code: code, details: details);
} 