import 'package:flutter/material.dart';
import 'package:hive_ui/theme/app_colors.dart';

/// Enum representing different types of user activities
enum ActivityType {
  joinedClub,
  attendedEvent,
  achievement,
  newFriend,
  postCreated,
}

/// Model class for user activity items shown in profiles and feeds
class Activity {
  /// Unique identifier for the activity
  final String id;

  /// Type of activity (joined club, attended event, etc)
  final ActivityType type;

  /// When the activity occurred
  final DateTime timestamp;

  /// Primary display text
  final String title;

  /// Secondary display text
  final String subtitle;

  /// Icon to display with the activity
  final IconData iconData;

  /// ID of the related entity (club, event, user, etc)
  final String relatedId;

  /// Constructor for Activity
  Activity({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.relatedId,
  });

  /// Helper method to format relative time
  String get timeAgo {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Get the appropriate color for the activity type
  Color get typeColor {
    switch (type) {
      case ActivityType.joinedClub:
        return Colors.purple;
      case ActivityType.attendedEvent:
        return Colors.orange;
      case ActivityType.achievement:
        return AppColors.gold;
      case ActivityType.newFriend:
        return Colors.blue;
      case ActivityType.postCreated:
        return Colors.green;
    }
  }

  /// Creates an Activity from JSON
  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: ActivityType.values.firstWhere(
        (e) => e.toString() == 'ActivityType.${json['type']}',
        orElse: () => ActivityType.postCreated,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      iconData: IconData(
        json['iconData'] as int,
        fontFamily: 'MaterialIcons',
      ),
      relatedId: json['relatedId'] as String,
    );
  }

  /// Converts Activity to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'subtitle': subtitle,
      'iconData': iconData.codePoint,
      'relatedId': relatedId,
    };
  }
}
