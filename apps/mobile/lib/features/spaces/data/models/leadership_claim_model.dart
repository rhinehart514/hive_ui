import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/domain/entities/leadership_claim_entity.dart';

/// Data model for leadership claim
class LeadershipClaimModel {
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
  LeadershipClaimModel({
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
  
  /// Convert to entity
  LeadershipClaimEntity toEntity() {
    return LeadershipClaimEntity(
      id: id,
      spaceId: spaceId,
      userId: userId,
      userName: userName,
      email: email,
      status: status,
      role: role,
      documentType: documentType,
      documentUrl: documentUrl,
      notes: notes,
      reviewNotes: reviewNotes,
      reviewerId: reviewerId,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      reviewedAt: reviewedAt,
    );
  }
  
  /// Create from entity
  factory LeadershipClaimModel.fromEntity(LeadershipClaimEntity entity) {
    return LeadershipClaimModel(
      id: entity.id,
      spaceId: entity.spaceId,
      userId: entity.userId,
      userName: entity.userName,
      email: entity.email,
      status: entity.status,
      role: entity.role,
      documentType: entity.documentType,
      documentUrl: entity.documentUrl,
      notes: entity.notes,
      reviewNotes: entity.reviewNotes,
      reviewerId: entity.reviewerId,
      submittedAt: entity.submittedAt,
      updatedAt: entity.updatedAt,
      reviewedAt: entity.reviewedAt,
    );
  }
  
  /// Convert status to string
  static String _statusToString(LeadershipClaimStatus status) {
    switch (status) {
      case LeadershipClaimStatus.unclaimed:
        return 'unclaimed';
      case LeadershipClaimStatus.pending:
        return 'pending';
      case LeadershipClaimStatus.approved:
        return 'approved';
      case LeadershipClaimStatus.rejected:
        return 'rejected';
    }
  }
  
  /// Convert string to status
  static LeadershipClaimStatus _stringToStatus(String status) {
    switch (status) {
      case 'unclaimed':
        return LeadershipClaimStatus.unclaimed;
      case 'pending':
        return LeadershipClaimStatus.pending;
      case 'approved':
        return LeadershipClaimStatus.approved;
      case 'rejected':
        return LeadershipClaimStatus.rejected;
      default:
        return LeadershipClaimStatus.unclaimed;
    }
  }
  
  /// Convert document type to string
  static String _documentTypeToString(VerificationDocumentType type) {
    switch (type) {
      case VerificationDocumentType.universityDocument:
        return 'university_document';
      case VerificationDocumentType.orgRoster:
        return 'org_roster';
      case VerificationDocumentType.emailVerification:
        return 'email_verification';
      case VerificationDocumentType.other:
        return 'other';
    }
  }
  
  /// Convert string to document type
  static VerificationDocumentType _stringToDocumentType(String type) {
    switch (type) {
      case 'university_document':
        return VerificationDocumentType.universityDocument;
      case 'org_roster':
        return VerificationDocumentType.orgRoster;
      case 'email_verification':
        return VerificationDocumentType.emailVerification;
      case 'other':
      default:
        return VerificationDocumentType.other;
    }
  }
  
  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'userName': userName,
      'email': email,
      'status': _statusToString(status),
      'role': role,
      'documentType': _documentTypeToString(documentType),
      'documentUrl': documentUrl,
      'notes': notes,
      'reviewNotes': reviewNotes,
      'reviewerId': reviewerId,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'reviewedAt': reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
    };
  }
  
  /// Create from Firestore document
  factory LeadershipClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LeadershipClaimModel(
      id: doc.id,
      spaceId: data['spaceId'] as String,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      status: _stringToStatus(data['status'] as String? ?? 'unclaimed'),
      role: data['role'] as String? ?? '',
      documentType: _stringToDocumentType(data['documentType'] as String? ?? 'other'),
      documentUrl: data['documentUrl'] as String?,
      notes: data['notes'] as String? ?? '',
      reviewNotes: data['reviewNotes'] as String?,
      reviewerId: data['reviewerId'] as String?,
      submittedAt: data['submittedAt'] != null ? 
        (data['submittedAt'] as Timestamp).toDate() : 
        DateTime.now(),
      updatedAt: data['updatedAt'] != null ? 
        (data['updatedAt'] as Timestamp).toDate() : 
        DateTime.now(),
      reviewedAt: data['reviewedAt'] != null ? 
        (data['reviewedAt'] as Timestamp).toDate() : 
        null,
    );
  }
} 