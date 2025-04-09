import 'package:hive_ui/features/spaces/domain/entities/claim_entity.dart';

/// Repository for managing leadership claims
abstract class ClaimsRepository {
  /// Submits a new leadership claim for a space
  Future<ClaimEntity> submitClaim({
    required String spaceId,
    required String userId,
    required String userName,
    required String userEmail,
    required String role,
    required String verificationMethod,
    String? notes,
  });
  
  /// Get claim by ID
  Future<ClaimEntity?> getClaimById(String claimId);
  
  /// Get claims by space ID
  Future<List<ClaimEntity>> getClaimsBySpaceId(String spaceId);
  
  /// Get claims by user ID
  Future<List<ClaimEntity>> getClaimsByUserId(String userId);
  
  /// Approve a claim
  Future<bool> approveClaim(String claimId, {String? adminId});
  
  /// Reject a claim
  Future<bool> rejectClaim(String claimId, {String? adminId, String? rejectionReason});
  
  /// Cancel a claim
  Future<bool> cancelClaim(String claimId);
} 