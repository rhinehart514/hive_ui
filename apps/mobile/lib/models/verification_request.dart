import 'package:flutter/foundation.dart';

/// Status of a verification request
enum VerificationRequestStatus {
  pending,
  approved,
  rejected,
  cancelled,
}

/// Type of verification being requested
enum VerificationType {
  standard, // Regular verification
  premium, // Verified+
}

/// Model representing a request for verification of a space or organization
@immutable
class VerificationRequest {
  final String id;
  final String objectId; // ID of the space or organization to verify
  final String objectType; // 'space' or 'organization'
  final String name; // Name of the space or organization
  final String requesterId; // User ID who submitted the request
  final String requesterName;
  final String? requesterAvatarUrl;
  final String? message; // Optional message with verification request
  final DateTime createdAt;
  final VerificationRequestStatus status;
  final VerificationType verificationType;
  final Map<String, String>? additionalDocuments; // Document name -> URL
  final String? approvedBy; // Admin who approved/rejected
  final String? rejectionReason;
  final DateTime? reviewedAt;

  const VerificationRequest({
    required this.id,
    required this.objectId,
    required this.objectType,
    required this.name,
    required this.requesterId,
    required this.requesterName,
    this.requesterAvatarUrl,
    this.message,
    required this.createdAt,
    required this.status,
    required this.verificationType,
    this.additionalDocuments,
    this.approvedBy,
    this.rejectionReason,
    this.reviewedAt,
  });

  /// Creates a copy of this VerificationRequest with the given fields replaced
  VerificationRequest copyWith({
    String? id,
    String? objectId,
    String? objectType,
    String? name,
    String? requesterId,
    String? requesterName,
    String? requesterAvatarUrl,
    String? message,
    DateTime? createdAt,
    VerificationRequestStatus? status,
    VerificationType? verificationType,
    Map<String, String>? additionalDocuments,
    String? approvedBy,
    String? rejectionReason,
    DateTime? reviewedAt,
  }) {
    return VerificationRequest(
      id: id ?? this.id,
      objectId: objectId ?? this.objectId,
      objectType: objectType ?? this.objectType,
      name: name ?? this.name,
      requesterId: requesterId ?? this.requesterId,
      requesterName: requesterName ?? this.requesterName,
      requesterAvatarUrl: requesterAvatarUrl ?? this.requesterAvatarUrl,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      verificationType: verificationType ?? this.verificationType,
      additionalDocuments: additionalDocuments ?? this.additionalDocuments,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  /// Create a VerificationRequest from a map (e.g. from Firestore)
  factory VerificationRequest.fromMap(Map<String, dynamic> map) {
    final DateTime createdAt = map['createdAt'] != null
        ? (map['createdAt'] is DateTime
            ? map['createdAt']
            : DateTime.parse(map['createdAt'].toString()))
        : DateTime.now();

    final DateTime? reviewedAt = map['reviewedAt'] != null
        ? (map['reviewedAt'] is DateTime
            ? map['reviewedAt']
            : DateTime.parse(map['reviewedAt'].toString()))
        : null;

    return VerificationRequest(
      id: map['id'] ?? '',
      objectId: map['objectId'] ?? '',
      objectType: map['objectType'] ?? 'space',
      name: map['name'] ?? '',
      requesterId: map['requesterId'] ?? '',
      requesterName: map['requesterName'] ?? '',
      requesterAvatarUrl: map['requesterAvatarUrl'],
      message: map['message'],
      createdAt: createdAt,
      status: _parseStatus(map['status']),
      verificationType: _parseType(map['verificationType']),
      additionalDocuments: map['additionalDocuments'] != null
          ? Map<String, String>.from(map['additionalDocuments'])
          : null,
      approvedBy: map['approvedBy'],
      rejectionReason: map['rejectionReason'],
      reviewedAt: reviewedAt,
    );
  }

  /// Convert this VerificationRequest to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'objectId': objectId,
      'objectType': objectType,
      'name': name,
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requesterAvatarUrl': requesterAvatarUrl,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'verificationType': verificationType.name,
      'additionalDocuments': additionalDocuments,
      'approvedBy': approvedBy,
      'rejectionReason': rejectionReason,
      'reviewedAt': reviewedAt?.toIso8601String(),
    };
  }

  /// Format the verification type for display
  String getVerificationTypeDisplay() {
    switch (verificationType) {
      case VerificationType.standard:
        return 'Verification';
      case VerificationType.premium:
        return 'Verified+';
    }
  }

  /// Parse the status from a string
  static VerificationRequestStatus _parseStatus(String? status) {
    if (status == null) return VerificationRequestStatus.pending;

    try {
      return VerificationRequestStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => VerificationRequestStatus.pending,
      );
    } catch (_) {
      return VerificationRequestStatus.pending;
    }
  }

  /// Parse the verification type from a string
  static VerificationType _parseType(String? type) {
    if (type == null) return VerificationType.standard;

    try {
      return VerificationType.values.firstWhere(
        (t) => t.name == type,
        orElse: () => VerificationType.standard,
      );
    } catch (_) {
      return VerificationType.standard;
    }
  }
}
