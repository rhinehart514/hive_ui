import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/features/spaces/domain/entities/claim_entity.dart';

/// Model for leadership claims at the data layer
class ClaimModel {
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
  
  /// Status of the claim as a string
  final String status;
  
  /// ID of admin who processed the claim
  final String? processedBy;
  
  /// Timestamp when the claim was processed
  final DateTime? processedAt;
  
  /// Reason for rejection if the claim was rejected
  final String? rejectionReason;
  
  /// Constructor
  const ClaimModel({
    required this.id,
    required this.spaceId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.role,
    required this.verificationMethod,
    this.notes,
    required this.submittedAt,
    required this.status,
    this.processedBy,
    this.processedAt,
    this.rejectionReason,
  });
  
  /// Convert to domain entity
  ClaimEntity toEntity() {
    return ClaimEntity(
      id: id,
      spaceId: spaceId,
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      role: role,
      verificationMethod: verificationMethod,
      notes: notes,
      submittedAt: submittedAt,
      status: _statusFromString(status),
      processedBy: processedBy,
      processedAt: processedAt,
      rejectionReason: rejectionReason,
    );
  }
  
  /// Create from domain entity
  factory ClaimModel.fromEntity(ClaimEntity entity) {
    return ClaimModel(
      id: entity.id,
      spaceId: entity.spaceId,
      userId: entity.userId,
      userName: entity.userName,
      userEmail: entity.userEmail,
      role: entity.role,
      verificationMethod: entity.verificationMethod,
      notes: entity.notes,
      submittedAt: entity.submittedAt,
      status: _statusToString(entity.status),
      processedBy: entity.processedBy,
      processedAt: entity.processedAt,
      rejectionReason: entity.rejectionReason,
    );
  }
  
  /// Create from Firestore document
  factory ClaimModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return ClaimModel(
      id: doc.id,
      spaceId: data['spaceId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      role: data['role'] ?? '',
      verificationMethod: data['verificationMethod'] ?? '',
      notes: data['notes'],
      submittedAt: (data['submittedAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
      processedBy: data['processedBy'],
      processedAt: data['processedAt'] != null 
          ? (data['processedAt'] as Timestamp).toDate() 
          : null,
      rejectionReason: data['rejectionReason'],
    );
  }
  
  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'spaceId': spaceId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'role': role,
      'verificationMethod': verificationMethod,
      'notes': notes,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'status': status,
      'processedBy': processedBy,
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }
  
  /// Convert string status to enum
  static ClaimStatus _statusFromString(String status) {
    switch (status) {
      case 'approved':
        return ClaimStatus.approved;
      case 'rejected':
        return ClaimStatus.rejected;
      case 'canceled':
        return ClaimStatus.canceled;
      case 'pending':
      default:
        return ClaimStatus.pending;
    }
  }
  
  /// Convert enum status to string
  static String _statusToString(ClaimStatus status) {
    switch (status) {
      case ClaimStatus.approved:
        return 'approved';
      case ClaimStatus.rejected:
        return 'rejected';
      case ClaimStatus.canceled:
        return 'canceled';
      case ClaimStatus.pending:
        return 'pending';
    }
  }
} 