import '../entities/verification_status.dart';
import '../repositories/verification_repository.dart';
// TODO: Add dependency injection for repository

/// Use case for updating the verification status of a user (Admin operation).
class UpdateVerificationStatusUseCase {
  final VerificationRepository _repository;

  UpdateVerificationStatusUseCase(this._repository);

  /// Executes the use case.
  Future<void> execute({
    required String userId,
    required VerificationStatus newStatus,
    VerificationLevel? newLevel,
    String? rejectionReason,
    required String verifierId,
  }) {
    // Basic validation
    if (newStatus == VerificationStatus.rejected && (rejectionReason == null || rejectionReason.isEmpty)) {
      throw ArgumentError('Rejection reason must be provided when status is rejected.');
    }
    if (newStatus == VerificationStatus.verified && newLevel == null) {
      throw ArgumentError('New verification level must be provided when status is verified.');
    }
    if (newStatus == VerificationStatus.verified && newLevel == VerificationLevel.public) {
       throw ArgumentError('Cannot verify a user to Public level.');
    }

    return _repository.updateVerificationStatus(
      userId: userId,
      newStatus: newStatus,
      newLevel: newLevel,
      rejectionReason: rejectionReason,
      verifierId: verifierId,
    );
  }
} 