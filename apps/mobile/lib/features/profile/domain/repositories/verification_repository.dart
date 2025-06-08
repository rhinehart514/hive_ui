import '../entities/verification_status.dart';

/// Repository interface for managing user verification processes
abstract class VerificationRepository {
  /// Get the verification status for a specific user
  Future<UserVerification?> getVerificationStatus(String userId);

  /// Watch the verification status for a specific user
  Stream<UserVerification?> watchVerificationStatus(String userId);

  /// Initiate the email verification process for the current user
  Future<void> requestEmailVerification(String userId);

  /// Submit a claim for Verified+ status
  /// 
  /// [userId] The ID of the user submitting the claim.
  /// [role] The specific Verified+ role being claimed (e.g., 'Org Leader').
  /// [justification] The reason or evidence provided by the user.
  /// [documentUrl] Optional URL to supporting documentation.
  Future<void> submitVerifiedPlusClaim({
    required String userId,
    required String role,
    required String justification,
    String? documentUrl,
  });

  // --- Admin/Manual Operations (Potentially moved to a separate admin feature) ---

  /// Update the verification status of a user (typically by an admin/verifier)
  /// 
  /// [userId] The ID of the user whose status is being updated.
  /// [newStatus] The new verification status (e.g., pending, verified, rejected).
  /// [newLevel] The new verification level if the status is 'verified'.
  /// [rejectionReason] Required if the status is 'rejected'.
  /// [verifierId] The ID of the admin/user performing the update.
  Future<void> updateVerificationStatus({
    required String userId,
    required VerificationStatus newStatus,
    VerificationLevel? newLevel, 
    String? rejectionReason,
    required String verifierId,
  });
} 