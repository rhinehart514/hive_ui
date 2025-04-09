import 'package:hive_ui/features/moderation/domain/entities/content_report_entity.dart';

/// Entity representing reported content with associated metadata
class ReportedContentEntity {
  /// Report details
  final ContentReportEntity report;
  
  /// Associated content title or name
  final String? contentTitle;
  
  /// Associated content text or description
  final String? contentText;
  
  /// Content creator's user ID
  final String? creatorId;
  
  /// Content creator's display name
  final String? creatorName;
  
  /// URL to creator's profile image
  final String? creatorImageUrl;
  
  /// Content creation timestamp
  final DateTime? contentCreatedAt;
  
  /// Additional custom data related to the content
  final Map<String, dynamic>? contentMetadata;
  
  /// Constructor
  const ReportedContentEntity({
    required this.report,
    this.contentTitle,
    this.contentText,
    this.creatorId,
    this.creatorName,
    this.creatorImageUrl,
    this.contentCreatedAt,
    this.contentMetadata,
  });
  
  /// Create a copy with modified fields
  ReportedContentEntity copyWith({
    ContentReportEntity? report,
    String? contentTitle,
    String? contentText,
    String? creatorId,
    String? creatorName,
    String? creatorImageUrl,
    DateTime? contentCreatedAt,
    Map<String, dynamic>? contentMetadata,
  }) {
    return ReportedContentEntity(
      report: report ?? this.report,
      contentTitle: contentTitle ?? this.contentTitle,
      contentText: contentText ?? this.contentText,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorImageUrl: creatorImageUrl ?? this.creatorImageUrl,
      contentCreatedAt: contentCreatedAt ?? this.contentCreatedAt,
      contentMetadata: contentMetadata ?? this.contentMetadata,
    );
  }
  
  /// Get display title for the reported content
  String getDisplayTitle() {
    if (contentTitle != null && contentTitle!.isNotEmpty) {
      return contentTitle!;
    }
    
    // Use content type as fallback title
    switch (report.contentType) {
      case ReportedContentType.post:
        return 'Post by ${creatorName ?? "Unknown User"}';
      case ReportedContentType.comment:
        return 'Comment by ${creatorName ?? "Unknown User"}';
      case ReportedContentType.message:
        return 'Message by ${creatorName ?? "Unknown User"}';
      case ReportedContentType.space:
        return 'Space: ${contentMetadata?['name'] ?? "Unknown Space"}';
      case ReportedContentType.event:
        return 'Event: ${contentMetadata?['name'] ?? "Unknown Event"}';
      case ReportedContentType.profile:
        return 'Profile: ${creatorName ?? "Unknown User"}';
    }
  }
  
  /// Get content preview text
  String getContentPreview({int maxLength = 100}) {
    if (contentText == null || contentText!.isEmpty) {
      return 'No content available';
    }
    
    if (contentText!.length <= maxLength) {
      return contentText!;
    }
    
    return '${contentText!.substring(0, maxLength)}...';
  }
  
  /// Get content age at time of report
  Duration? getContentAgeAtReport() {
    if (contentCreatedAt == null) return null;
    
    return report.createdAt.difference(contentCreatedAt!);
  }
  
  /// Get formatted timestamp for content creation
  String getFormattedCreationTime() {
    if (contentCreatedAt == null) return 'Unknown time';
    
    final now = DateTime.now();
    final difference = now.difference(contentCreatedAt!);
    
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }
  
  /// Check if content is from a verified creator
  bool get isFromVerifiedCreator {
    return contentMetadata?['isVerified'] == true;
  }
} 