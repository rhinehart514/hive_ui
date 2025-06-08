import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum VerificationRequestStatus {
  pending,
  approved,
  rejected
}

class VerificationRequest extends Equatable {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String role;
  final String justification;
  final String? documentUrl;
  final VerificationRequestStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final String? rejectionReason;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.role,
    required this.justification,
    this.documentUrl,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.rejectionReason,
  });

  VerificationRequest copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? role,
    String? justification,
    String? documentUrl,
    VerificationRequestStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? reviewedBy,
    String? rejectionReason,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      justification: justification ?? this.justification,
      documentUrl: documentUrl ?? this.documentUrl,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  factory VerificationRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return VerificationRequest(
      id: doc.id,
      userId: data['userId'] as String,
      userEmail: data['userEmail'] as String,
      userName: data['userName'] as String,
      role: data['role'] as String,
      justification: data['justification'] as String,
      documentUrl: data['documentUrl'] as String?,
      status: _statusFromString(data['status'] as String),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null 
        ? (data['updatedAt'] as Timestamp).toDate() 
        : null,
      reviewedBy: data['reviewedBy'] as String?,
      rejectionReason: data['rejectionReason'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'role': role,
      'justification': justification,
      'documentUrl': documentUrl,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'reviewedBy': reviewedBy,
      'rejectionReason': rejectionReason,
    };
  }

  static VerificationRequestStatus _statusFromString(String status) {
    switch (status) {
      case 'approved':
        return VerificationRequestStatus.approved;
      case 'rejected':
        return VerificationRequestStatus.rejected;
      case 'pending':
      default:
        return VerificationRequestStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
    id, 
    userId, 
    userEmail,
    userName,
    role,
    justification,
    documentUrl,
    status,
    createdAt,
    updatedAt,
    reviewedBy,
    rejectionReason,
  ];
} 