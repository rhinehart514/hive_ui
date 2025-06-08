import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Defines the type of repost content
enum RepostContentType {
  /// Standard repost with a comment
  standard,

  /// Repost with added personal experience or review
  review,

  /// Repost with a quote commenting on the event
  quote,

  /// Repost with added contextual information or facts
  informative,

  /// Repost with a question or poll for followers
  question,

  /// Repost that includes recommendations or advice
  recommendation,

  /// Repost that highlights or showcases an event
  highlight,
}

/// Extension to add properties to RepostContentType
extension RepostContentTypeProperties on RepostContentType {
  /// Get the display name for the repost type
  String get displayName {
    switch (this) {
      case RepostContentType.standard:
        return 'Repost';
      case RepostContentType.review:
        return 'Review';
      case RepostContentType.quote:
        return 'Quote';
      case RepostContentType.informative:
        return 'Info';
      case RepostContentType.question:
        return 'Question';
      case RepostContentType.recommendation:
        return 'Recommendation';
      case RepostContentType.highlight:
        return 'Highlight';
    }
  }

  /// Get the icon for the repost type
  IconData get icon {
    switch (this) {
      case RepostContentType.standard:
        return Icons.repeat;
      case RepostContentType.review:
        return Icons.star_rate;
      case RepostContentType.quote:
        return Icons.format_quote;
      case RepostContentType.informative:
        return Icons.info;
      case RepostContentType.question:
        return Icons.question_answer;
      case RepostContentType.recommendation:
        return Icons.thumbs_up_down;
      case RepostContentType.highlight:
        return Icons.push_pin;
    }
  }

  /// Get the color for the repost type badge
  Color get color {
    switch (this) {
      case RepostContentType.standard:
        return AppColors.info;
      case RepostContentType.review:
        return const Color(0xFFFF9800); // Orange
      case RepostContentType.quote:
        return AppColors.success;
      case RepostContentType.informative:
        return const Color(0xFF64B5F6); // Blue
      case RepostContentType.question:
        return const Color(0xFF9C27B0); // Purple
      case RepostContentType.recommendation:
        return const Color(0xFF4CAF50); // Green
      case RepostContentType.highlight:
        return AppColors.gold;
    }
  }

  /// Get the subtitle description for the repost type
  String get description {
    switch (this) {
      case RepostContentType.standard:
        return 'Share this event with your followers';
      case RepostContentType.review:
        return 'Share your experience or review';
      case RepostContentType.quote:
        return 'Add your thoughts when sharing';
      case RepostContentType.informative:
        return 'Add additional information or context';
      case RepostContentType.question:
        return 'Ask a question or create a poll';
      case RepostContentType.recommendation:
        return 'Recommend this event to your followers';
      case RepostContentType.highlight:
        return 'Highlight and feature this event';
    }
  }
}
