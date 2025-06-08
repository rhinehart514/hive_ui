import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/leadership_claim_repository.dart';

/// Use case for creating a leadership claim
class CreateLeadershipClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  CreateLeadershipClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<LeadershipClaimEntity> execute({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String role,
    required VerificationDocumentType documentType,
    String? documentUrl,
    required String notes,
  }) {
    return _repository.createClaim(
      spaceId: spaceId,
      userId: userId,
      userName: userName,
      email: email,
      role: role,
      documentType: documentType,
      documentUrl: documentUrl,
      notes: notes,
    );
  }
}

/// Use case for getting a claim for a space
class GetSpaceClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  GetSpaceClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<LeadershipClaimEntity?> execute(String spaceId) {
    return _repository.getClaimForSpace(spaceId);
  }
}

/// Use case for getting all pending claims
class GetPendingClaimsUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  GetPendingClaimsUseCase(this._repository);
  
  /// Execute the use case
  Future<List<LeadershipClaimEntity>> execute() {
    return _repository.getAllPendingClaims();
  }
}

/// Use case for getting claims by user
class GetUserClaimsUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  GetUserClaimsUseCase(this._repository);
  
  /// Execute the use case
  Future<List<LeadershipClaimEntity>> execute(String userId) {
    return _repository.getClaimsByUser(userId);
  }
}

/// Use case for approving a claim
class ApproveClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  ApproveClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<LeadershipClaimEntity> execute({
    required String claimId,
    required String reviewerId,
    String? reviewNotes,
  }) {
    return _repository.approveClaim(
      claimId: claimId,
      reviewerId: reviewerId,
      reviewNotes: reviewNotes,
    );
  }
}

/// Use case for rejecting a claim
class RejectClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  RejectClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<LeadershipClaimEntity> execute({
    required String claimId,
    required String reviewerId,
    required String reviewNotes,
  }) {
    return _repository.rejectClaim(
      claimId: claimId,
      reviewerId: reviewerId,
      reviewNotes: reviewNotes,
    );
  }
}

/// Use case for canceling a claim
class CancelClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  CancelClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<bool> execute({
    required String claimId,
    required String userId,
  }) {
    return _repository.cancelClaim(
      claimId: claimId,
      userId: userId,
    );
  }
}

/// Use case for checking if a space requires a leadership claim
class CheckSpaceRequiresClaimUseCase {
  final LeadershipClaimRepository _repository;
  
  /// Constructor
  CheckSpaceRequiresClaimUseCase(this._repository);
  
  /// Execute the use case
  Future<bool> execute(String spaceId) {
    return _repository.spaceRequiresClaim(spaceId);
  }
} 