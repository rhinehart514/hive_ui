import '../entities/verification_request.dart';

/// Repository interface for admin verification operations
abstract class VerificationAdminRepository {
  /// Get a list of pending verification requests
  Stream<List<VerificationRequest>> getPendingRequests();
  
  /// Get a list of all verification requests with optional filtering
  Stream<List<VerificationRequest>> getAllRequests({
    VerificationRequestStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });
  
  /// Get a specific verification request by ID
  Future<VerificationRequest?> getRequestById(String requestId);
  
  /// Approve a verification request
  /// 
  /// [requestId] The ID of the request to approve
  /// [adminId] The ID of the admin approving the request
  /// [notes] Optional notes from the admin
  Future<void> approveRequest({
    required String requestId,
    required String adminId,
    String? notes,
  });
  
  /// Reject a verification request
  /// 
  /// [requestId] The ID of the request to reject
  /// [adminId] The ID of the admin rejecting the request
  /// [reason] The reason for rejection (required)
  Future<void> rejectRequest({
    required String requestId,
    required String adminId,
    required String reason,
  });
  
  /// Flag a verification request for further review
  /// 
  /// [requestId] The ID of the request to flag
  /// [adminId] The ID of the admin flagging the request
  /// [notes] Notes explaining why the request is flagged
  Future<void> flagRequestForReview({
    required String requestId,
    required String adminId,
    required String notes,
  });
  
  /// Get admin audit log for verification actions
  Future<List<Map<String, dynamic>>> getVerificationAuditLog({
    DateTime? startDate,
    DateTime? endDate,
    String? adminId,
    int? limit,
  });
} 