import 'package:cloud_firestore/cloud_firestore.dart';

/// The different types of content that can be reported
enum ReportedContentType {
  post,
  comment,
  message,
  space,
  event,
  profile,
}

/// The status of a content report
enum ReportStatus {
  pending,
  underReview,
  resolved,
  dismissed,
}

/// The reason for reporting content
enum ReportReason {
  spam,
  harassment,
  hateSpeech,
  inappropriateContent,
  violatesGuidelines,
  other,
}

/// Model for content reports in the data layer
class ContentReportModel {
  /// Unique identifier for the report
  final String id;
  
  /// The user who reported the content
  final String reporterUserId;
  
  /// Type of content that was reported
  final ReportedContentType contentType;
  
  /// ID of the content that was reported
  final String contentId;
  
  /// Reason for the report
  final ReportReason reason;
  
  /// Additional details provided by the reporter
  final String? details;
  
  /// Current status of the report
  final ReportStatus status;
  
  /// Timestamp when the report was created
  final DateTime createdAt;
  
  /// Timestamp when the report was last updated
  final DateTime updatedAt;
  
  /// ID of the moderator who handled the report (if any)
  final String? resolvedByUserId;
  
  /// Notes added by the moderator
  final String? moderatorNotes;
  
  /// Action taken on the report (remove, ban, etc.)
  final String? actionTaken;
  
  /// Constructor
  ContentReportModel({
    required this.id,
    required this.reporterUserId,
    required this.contentType,
    required this.contentId,
    required this.reason,
    this.details,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolvedByUserId,
    this.moderatorNotes,
    this.actionTaken,
  });
  
  /// Create a copy with modified fields
  ContentReportModel copyWith({
    String? id,
    String? reporterUserId,
    ReportedContentType? contentType,
    String? contentId,
    ReportReason? reason,
    String? details,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? resolvedByUserId,
    String? moderatorNotes,
    String? actionTaken,
  }) {
    return ContentReportModel(
      id: id ?? this.id,
      reporterUserId: reporterUserId ?? this.reporterUserId,
      contentType: contentType ?? this.contentType,
      contentId: contentId ?? this.contentId,
      reason: reason ?? this.reason,
      details: details ?? this.details,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedByUserId: resolvedByUserId ?? this.resolvedByUserId,
      moderatorNotes: moderatorNotes ?? this.moderatorNotes,
      actionTaken: actionTaken ?? this.actionTaken,
    );
  }
  
  /// Create from Firestore document
  factory ContentReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse report reason
    final reasonStr = data['reason'] as String? ?? 'other';
    final reason = ReportReason.values.firstWhere(
      (e) => e.toString().split('.').last == reasonStr,
      orElse: () => ReportReason.other,
    );
    
    // Parse content type
    final contentTypeStr = data['contentType'] as String? ?? 'post';
    final contentType = ReportedContentType.values.firstWhere(
      (e) => e.toString().split('.').last == contentTypeStr,
      orElse: () => ReportedContentType.post,
    );
    
    // Parse report status
    final statusStr = data['status'] as String? ?? 'pending';
    final status = ReportStatus.values.firstWhere(
      (e) => e.toString().split('.').last == statusStr,
      orElse: () => ReportStatus.pending,
    );
    
    return ContentReportModel(
      id: doc.id,
      reporterUserId: data['reporterUserId'] as String? ?? '',
      contentType: contentType,
      contentId: data['contentId'] as String? ?? '',
      reason: reason,
      details: data['details'] as String?,
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedByUserId: data['resolvedByUserId'] as String?,
      moderatorNotes: data['moderatorNotes'] as String?,
      actionTaken: data['actionTaken'] as String?,
    );
  }
  
  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'reporterUserId': reporterUserId,
      'contentType': contentType.toString().split('.').last,
      'contentId': contentId,
      'reason': reason.toString().split('.').last,
      'details': details,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'resolvedByUserId': resolvedByUserId,
      'moderatorNotes': moderatorNotes,
      'actionTaken': actionTaken,
    };
  }
} 