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

/// Domain entity for content reports
class ContentReportEntity {
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
  const ContentReportEntity({
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
  ContentReportEntity copyWith({
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
    return ContentReportEntity(
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
  
  /// Check if the report is pending action
  bool get isPending => status == ReportStatus.pending;
  
  /// Check if the report is under review
  bool get isUnderReview => status == ReportStatus.underReview;
  
  /// Check if the report is resolved
  bool get isResolved => status == ReportStatus.resolved;
  
  /// Check if the report is dismissed
  bool get isDismissed => status == ReportStatus.dismissed;
  
  /// Check if the report has been processed by a moderator
  bool get isProcessed => isResolved || isDismissed;
  
  /// Get time since the report was created
  Duration get ageOfReport => DateTime.now().difference(createdAt);
  
  /// Get a human-readable description of the report
  String getReportDescription() {
    String typeStr = '';
    switch (contentType) {
      case ReportedContentType.post:
        typeStr = 'Post';
        break;
      case ReportedContentType.comment:
        typeStr = 'Comment';
        break;
      case ReportedContentType.message:
        typeStr = 'Message';
        break;
      case ReportedContentType.space:
        typeStr = 'Space';
        break;
      case ReportedContentType.event:
        typeStr = 'Event';
        break;
      case ReportedContentType.profile:
        typeStr = 'Profile';
        break;
    }
    
    String reasonStr = '';
    switch (reason) {
      case ReportReason.spam:
        reasonStr = 'Spam';
        break;
      case ReportReason.harassment:
        reasonStr = 'Harassment';
        break;
      case ReportReason.hateSpeech:
        reasonStr = 'Hate Speech';
        break;
      case ReportReason.inappropriateContent:
        reasonStr = 'Inappropriate Content';
        break;
      case ReportReason.violatesGuidelines:
        reasonStr = 'Violates Guidelines';
        break;
      case ReportReason.other:
        reasonStr = 'Other';
        break;
    }
    
    return '$typeStr reported for $reasonStr';
  }
} 