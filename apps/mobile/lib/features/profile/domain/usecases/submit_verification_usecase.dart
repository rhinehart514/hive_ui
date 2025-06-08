import '../repositories/verification_repository.dart';
// TODO: Add dependency injection for repository

/// Use case for requesting email verification for the current user.
class RequestEmailVerificationUseCase {
  final VerificationRepository _repository;

  RequestEmailVerificationUseCase(this._repository);

  /// Executes the use case.
  Future<void> execute(String userId) {
    return _repository.requestEmailVerification(userId);
  }
}

/// Use case for submitting a Verified+ claim.
class SubmitVerifiedPlusClaimUseCase {
  final VerificationRepository _repository;

  SubmitVerifiedPlusClaimUseCase(this._repository);

  /// Executes the use case.
  Future<void> execute({
    required String userId,
    required String role,
    required String justification,
    String? documentUrl,
  }) {
    return _repository.submitVerifiedPlusClaim(
      userId: userId,
      role: role,
      justification: justification,
      documentUrl: documentUrl,
    );
  }
} 