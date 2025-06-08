import 'package:flutter/foundation.dart';

/// Status of a leadership claim
enum LeadershipClaimStatus {
  /// Space is unclaimed
  unclaimed,
  
  /// Claim is pending verification
  pending,
  
  /// Claim is approved
  approved,
  
  /// Claim was rejected
  rejected,
}

/// Type of verification document provided
enum VerificationDocumentType {
  /// Official university documentation
  universityDocument,
  
  /// Student organization roster
  orgRoster,
  
  /// Email verification
  emailVerification,
  
  /// Other documentation
  other,
}

/// Entity representing a leadership claim for a space
@immutable
class LeadershipClaimEntity {
  /// The ID of the claim
  final String id;
  
  /// The ID of the space being claimed
  final String spaceId;
  
  /// The ID of the user making the claim
  final String userId;
  
  /// The user's display name
  final String userName;
  
  /// The user's email
  final String email;
  
  /// The current status of the claim
  final LeadershipClaimStatus status;
  
  /// The role claimed by the user
  final String role;
  
  /// Type of verification document provided
  final VerificationDocumentType documentType;
  
  /// URL of the verification document if any
  final String? documentUrl;
  
  /// Notes provided by the claimant
  final String notes;
  
  /// Notes from the reviewer
  final String? reviewNotes;
  
  /// ID of the user who reviewed the claim
  final String? reviewerId;
  
  /// When the claim was submitted
  final DateTime submittedAt;
  
  /// When the claim was last updated
  final DateTime updatedAt;
  
  /// When the claim was reviewed
  final DateTime? reviewedAt;
  
  /// Constructor
  const LeadershipClaimEntity({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    required this.email,
    required this.status,
    required this.role,
    required this.documentType,
    this.documentUrl,
    required this.notes,
    this.reviewNotes,
    this.reviewerId,
    required this.submittedAt,
    required this.updatedAt,
    this.reviewedAt,
  });
  
  /// Create a new claim with 'unclaimed' status
  factory LeadershipClaimEntity.unclaimed({
    required String id,
    required String spaceId,
  }) {
    final now = DateTime.now();
    return LeadershipClaimEntity(
      id: id,
      spaceId: spaceId,
      userId: '',
      userName: '',
      email: '',
      status: LeadershipClaimStatus.unclaimed,
      role: '',
      documentType: VerificationDocumentType.other,
      notes: '',
      submittedAt: now,
      updatedAt: now,
    );
  }
  
  /// Create a new pending claim
  factory LeadershipClaimEntity.pending({
    required String id,
    required String spaceId,
    required String userId,
    required String userName,
    required String email,
    required String role,
    required VerificationDocumentType documentType,
    String? documentUrl,
    required String notes,
  }) {
    final now = DateTime.now();
    return LeadershipClaimEntity(
      id: id,
      spaceId: spaceId,
      userId: userId,
      userName: userName,
      email: email,
      status: LeadershipClaimStatus.pending,
      role: role,
      documentType: documentType,
      documentUrl: documentUrl,
      notes: notes,
      submittedAt: now,
      updatedAt: now,
    );
  }
  
  /// Create a copy with modified fields
  LeadershipClaimEntity copyWith({
    String? id,
    String? spaceId,
    String? userId,
    String? userName,
    String? email,
    LeadershipClaimStatus? status,
    String? role,
    VerificationDocumentType? documentType,
    String? documentUrl,
    String? notes,
    String? reviewNotes,
    String? reviewerId,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
  }) {
    return LeadershipClaimEntity(
      id: id ?? this.id,
      spaceId: spaceId ?? this.spaceId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      email: email ?? this.email,
      status: status ?? this.status,
      role: role ?? this.role,
      documentType: documentType ?? this.documentType,
      documentUrl: documentUrl ?? this.documentUrl,
      notes: notes ?? this.notes,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      reviewerId: reviewerId ?? this.reviewerId,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
  
  /// Update the claim status
  LeadershipClaimEntity withStatus(
    LeadershipClaimStatus newStatus, {
    String? reviewNotes,
    String? reviewerId,
  }) {
    return copyWith(
      status: newStatus,
      reviewNotes: reviewNotes,
      reviewerId: reviewerId,
      reviewedAt: newStatus == LeadershipClaimStatus.pending ? null : DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  
  /// Check if claim is for university email
  bool get isUniversityEmail {
    // Check if email ends with .edu or other university domains
    return email.endsWith('.edu') || email.contains('@university.');
  }
  
  /// Get a simple status description
  String get statusDescription {
    switch (status) {
      case LeadershipClaimStatus.unclaimed:
        return 'Unclaimed';
      case LeadershipClaimStatus.pending:
        return 'Pending Review';
      case LeadershipClaimStatus.approved:
        return 'Approved';
      case LeadershipClaimStatus.rejected:
        return 'Rejected';
    }
  }
} 