import 'package:cloud_firestore/cloud_firestore.dart';

/// Verification level for user accounts
enum VerificationLevel {
  /// Unverified public account with limited access
  public,
  
  /// Standard verified account with full access (email verified)
  verified,
  
  /// Enhanced verification for student leaders
  verifiedPlus,
}

/// Status of a verification request
enum VerificationStatus {
  /// Not submitted for verification
  notVerified,
  
  /// Verification request is pending review
  pending,
  
  /// Verification request was rejected
  rejected,
  
  /// Successfully verified
  verified,
}

/// User verification information
class UserVerification {
  final String userId;
  final VerificationLevel level;
  final VerificationStatus status;
  final DateTime? submittedAt;
  final DateTime? verifiedAt;
  final String? verificationCode;
  final String? rejectionReason;
  final String? verifierId;
  final Map<String, dynamic>? metadata;
  final String? connectedSpaceId;

  const UserVerification({
    required this.userId,
    required this.level,
    required this.status,
    this.submittedAt,
    this.verifiedAt,
    this.verificationCode,
    this.rejectionReason,
    this.verifierId,
    this.metadata,
    this.connectedSpaceId,
  });

  /// Create an empty verification instance
  factory UserVerification.empty(String userId) {
    return UserVerification(
      userId: userId,
      level: VerificationLevel.public,
      status: VerificationStatus.notVerified,
    );
  }
  
  /// Check if verification is pending
  bool get isPending => status == VerificationStatus.pending;
  
  /// Check if verification is rejected
  bool get isRejected => status == VerificationStatus.rejected;
  
  /// Check if verification is verified
  bool get isVerified => status == VerificationStatus.verified;
  
  /// Check if account is public
  bool get isPublic => level == VerificationLevel.public;
  
  /// Check if account is standard verified
  bool get isStandardVerified => level == VerificationLevel.verified;
  
  /// Check if account is verified plus
  bool get isVerifiedPlus => level == VerificationLevel.verifiedPlus;
  
  /// Get string representation of verification level
  String get levelString {
    switch (level) {
      case VerificationLevel.public:
        return 'Public';
      case VerificationLevel.verified:
        return 'Verified';
      case VerificationLevel.verifiedPlus:
        return 'Verified+';
    }
  }
  
  /// Get string representation of verification status
  String get statusString {
    switch (status) {
      case VerificationStatus.notVerified:
        return 'Not Verified';
      case VerificationStatus.pending:
        return 'Pending';
      case VerificationStatus.rejected:
        return 'Rejected';
      case VerificationStatus.verified:
        return 'Verified';
    }
  }
  
  /// Create a copy of the verification with updated fields
  UserVerification copyWith({
    String? userId,
    VerificationLevel? level,
    VerificationStatus? status,
    DateTime? submittedAt,
    DateTime? verifiedAt,
    String? verificationCode,
    String? rejectionReason,
    String? verifierId,
    Map<String, dynamic>? metadata,
    String? connectedSpaceId,
  }) {
    return UserVerification(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      verificationCode: verificationCode ?? this.verificationCode,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      verifierId: verifierId ?? this.verifierId,
      metadata: metadata ?? this.metadata,
      connectedSpaceId: connectedSpaceId ?? this.connectedSpaceId,
    );
  }
  
  /// Convert verification to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'level': level.index,
      'status': status.index,
      'submittedAt': submittedAt != null ? Timestamp.fromDate(submittedAt!) : null,
      'verifiedAt': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'verificationCode': verificationCode,
      'rejectionReason': rejectionReason,
      'verifierId': verifierId,
      'metadata': metadata,
      'connectedSpaceId': connectedSpaceId,
    };
  }
  
  /// Create verification from JSON
  factory UserVerification.fromJson(Map<String, dynamic> json) {
    return UserVerification(
      userId: json['userId'],
      level: VerificationLevel.values[json['level']],
      status: VerificationStatus.values[json['status']],
      submittedAt: json['submittedAt'] != null 
          ? (json['submittedAt'] as Timestamp).toDate() 
          : null,
      verifiedAt: json['verifiedAt'] != null 
          ? (json['verifiedAt'] as Timestamp).toDate() 
          : null,
      verificationCode: json['verificationCode'],
      rejectionReason: json['rejectionReason'],
      verifierId: json['verifierId'],
      metadata: json['metadata'],
      connectedSpaceId: json['connectedSpaceId'],
    );
  }
  
  /// Create verification from Firestore document
  factory UserVerification.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserVerification.fromJson(data);
  }
} 