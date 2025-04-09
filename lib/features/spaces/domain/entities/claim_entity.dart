import 'package:equatable/equatable.dart';

/// Status of a leadership claim
enum ClaimStatus {
  /// Claim is pending review
  pending,
  /// Claim has been approved
  approved,
  /// Claim has been rejected
  rejected,
  /// Claim has been canceled by the user
  canceled,
}

/// Entity representing a leadership claim for a space
class ClaimEntity extends Equatable {
  /// Unique identifier for the claim
  final String id;
  
  /// ID of the space being claimed
  final String spaceId;
  
  /// ID of the user making the claim
  final String userId;
  
  /// Name of the user making the claim
  final String userName;
  
  /// Email of the user making the claim
  final String userEmail;
  
  /// Role of the user in the organization
  final String role;
  
  /// Method of verification (e.g., official email, ID card)
  final String verificationMethod;
  
  /// Additional notes provided by the user
  final String? notes;
  
  /// Timestamp when the claim was submitted
  final DateTime submittedAt;
  
  /// Status of the claim
  final ClaimStatus status;
  
  /// ID of admin who processed the claim
  final String? processedBy;
  
  /// Timestamp when the claim was processed
  final DateTime? processedAt;
  
  /// Reason for rejection if the claim was rejected
  final String? rejectionReason;
  
  /// Constructor
  const ClaimEntity({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.verificationMethod,
    this.notes,
    required this.submittedAt,
    this.status = ClaimStatus.pending,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
  });
  
  /// Props for Equatable
  @override
  List<Object?> get props => [
    id,
    spaceId,
    userId,
    userName,
    userEmail,
    role,
    verificationMethod,
    notes,
    submittedAt,
    status,
    processedBy,
    processedAt,
    rejectionReason,
  ];
  
  /// Create a copy with modified fields
  ClaimEntity copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? userName,
    String? userEmail,
    String? role,
    String? verificationMethod,
    String? notes,
    DateTime? submittedAt,
    ClaimStatus? status,
    String? processedBy,
    DateTime? processedAt,
    String? rejectionReason,
  }) {
    return ClaimEntity(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      role: role ?? this.role,
      verificationMethod: verificationMethod ?? this.verificationMethod,
      notes: notes ?? this.notes,
      submittedAt: submittedAt ?? this.submittedAt,
      status: status ?? this.status,
      processedBy: processedBy ?? this.processedBy,
      processedAt: processedAt ?? this.processedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
} 