import 'package:flutter/material.dart';
import '../../domain/entities/content_report_entity.dart';
import '../../../../theme/app_colors.dart';
import '../../../../widgets/common/glass_container.dart';

class ReportListItem extends StatelessWidget {
  final ContentReportEntity report;
  final VoidCallback onTap;

  const ReportListItem({
    Key? key,
    required this.report,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassContainer(
          borderRadius: 12,
          withBorder: true,
          withShadow: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with report type and status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _getStatusColor().withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTypeIcon(),
                      size: 20,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getContentTypeLabel(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor(),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusLabel(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Report content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Report reason
                    Row(
                      children: [
                        const Text(
                          'Reason:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getReasonLabel(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Report time
                    Row(
                      children: [
                        const Text(
                          'Reported:',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _getTimeAgo(),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    
                    // Report details if available
                    if (report.details != null && report.details!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Details:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        report.details!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              
              // Action buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('View'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.gold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Get color based on report status
  Color _getStatusColor() {
    switch (report.status) {
      case ReportStatus.pending:
        return Colors.orangeAccent;
      case ReportStatus.underReview:
        return Colors.blueAccent;
      case ReportStatus.resolved:
        return Colors.greenAccent;
      case ReportStatus.dismissed:
        return Colors.grey;
    }
  }

  // Get icon based on content type
  IconData _getTypeIcon() {
    switch (report.contentType) {
      case ReportedContentType.post:
        return Icons.article;
      case ReportedContentType.comment:
        return Icons.comment;
      case ReportedContentType.message:
        return Icons.message;
      case ReportedContentType.space:
        return Icons.group;
      case ReportedContentType.event:
        return Icons.event;
      case ReportedContentType.profile:
        return Icons.person;
    }
  }

  // Get human-readable content type
  String _getContentTypeLabel() {
    switch (report.contentType) {
      case ReportedContentType.post:
        return 'Post';
      case ReportedContentType.comment:
        return 'Comment';
      case ReportedContentType.message:
        return 'Message';
      case ReportedContentType.space:
        return 'Space';
      case ReportedContentType.event:
        return 'Event';
      case ReportedContentType.profile:
        return 'Profile';
    }
  }

  // Get human-readable status label
  String _getStatusLabel() {
    switch (report.status) {
      case ReportStatus.pending:
        return 'Pending';
      case ReportStatus.underReview:
        return 'Under Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.dismissed:
        return 'Dismissed';
    }
  }

  // Get human-readable reason label
  String _getReasonLabel() {
    switch (report.reason) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.hateSpeech:
        return 'Hate Speech';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.violatesGuidelines:
        return 'Violates Guidelines';
      case ReportReason.other:
        return 'Other';
    }
  }

  // Get time ago in a human-readable format
  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(report.createdAt);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year(s) ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month(s) ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day(s) ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour(s) ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute(s) ago';
    } else {
      return 'Just now';
    }
  }
} 