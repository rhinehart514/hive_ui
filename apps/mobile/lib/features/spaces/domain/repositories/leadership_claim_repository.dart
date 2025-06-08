import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';

/// Exception thrown when a claim operation fails
class LeadershipClaimException implements Exception {
  /// Error message
  final String message;
  
  /// Constructor
  LeadershipClaimException(this.message);
  
  @override
  String toString() => 'LeadershipClaimException: $message';
}

/// Repository interface for leadership claim operations
abstract class LeadershipClaimRepository {
  /// Get claim for a space
  /// 
  /// If no claim exists, returns null
  Future<LeadershipClaimEntity?> getClaimForSpace(String spaceId);
  
  /// Get all claims with the given status
  Future<List<LeadershipClaimEntity>> getClaimsByStatus(LeadershipClaimStatus status);
  
  /// Get all claims submitted by a user
  Future<List<LeadershipClaimEntity>> getClaimsByUser(String userId);
  
  /// Create a new leadership claim
  /// 
  /// Throws [LeadershipClaimException] if claim already exists or user isn't eligible
  Future<LeadershipClaimEntity> createClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String role,
    required VerificationDocumentType documentType,
    String? documentUrl,
    required String notes,
  });
  
  /// Update an existing claim
  Future<LeadershipClaimEntity> updateClaim(LeadershipClaimEntity claim);
  
  /// Approve a pending claim
  /// 
  /// Throws [LeadershipClaimException] if claim isn't pending or reviewer isn't authorized
  Future<LeadershipClaimEntity> approveClaim({
    required String claimId,
    required String reviewerId,
    String? reviewNotes,
  });
  
  /// Reject a pending claim
  /// 
  /// Throws [LeadershipClaimException] if claim isn't pending or reviewer isn't authorized
  Future<LeadershipClaimEntity> rejectClaim({
    required String claimId,
    required String reviewerId,
    required String reviewNotes,
  });
  
  /// Cancel a pending claim
  /// 
  /// This can only be done by the user who created the claim
  /// Throws [LeadershipClaimException] if the user isn't the original claimant
  Future<bool> cancelClaim({
    required String claimId,
    required String userId,
  });
  
  /// Check if a space requires leadership claim
  /// 
  /// Returns true for pre-seeded spaces, false for HIVE-exclusive spaces
  Future<bool> spaceRequiresClaim(String spaceId);
  
  /// Get all pending claims
  Future<List<LeadershipClaimEntity>> getAllPendingClaims();
  
  /// Get all claims
  Future<List<LeadershipClaimEntity>> getAllClaims();
} 