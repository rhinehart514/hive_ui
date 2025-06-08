import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'event.dart';
import 'user_profile.dart';

/// The type of repost content
enum RepostContentType {
  /// Standard repost with no added content
  standard,
  
  /// Repost with a text comment
  comment,
  
  /// Repost with a recommendation
  recommendation,
  
  /// Repost with a critical review
  critical
}

/// Extension to convert string to RepostContentType
extension RepostContentTypeExtension on RepostContentType {
  /// Get string representation of repost type
  String toShortString() {
    return toString().split('.').last;
  }
  
  /// Convert string to RepostContentType
  static RepostContentType fromString(String? typeString) {
    switch (typeString?.toLowerCase()) {
      case 'comment':
        return RepostContentType.comment;
      case 'recommendation':
        return RepostContentType.recommendation;
      case 'critical':
        return RepostContentType.critical;
      default:
        return RepostContentType.standard;
    }
  }
}

/// Model class for representing a repost of an event
class RepostItem {
  /// Unique ID of the repost
  final String id;
  
  /// The original event being reposted
  final Event event;
  
  /// Profile of the user who reposted
  final UserProfile reposterProfile;
  
  /// Optional comment added by the reposter
  final String? comment;
  
  /// When the repost was created
  final DateTime repostTime;
  
  /// Type of repost content
  final RepostContentType type;
  
  /// Number of likes this repost has received
  final int likeCount;
  
  /// Constructor
  const RepostItem({
    required this.id,
    required this.event,
    required this.reposterProfile,
    this.comment,
    required this.repostTime,
    this.type = RepostContentType.standard,
    this.likeCount = 0,
  });
  
  /// Create a RepostItem from Firestore data
  factory RepostItem.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    Event event,
    UserProfile reposterProfile,
  ) {
    final data = snapshot.data()!;
    
    // Helper to safely parse timestamp
    DateTime parseTimestamp(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        debugPrint('Error parsing repost time: $e');
        return DateTime.now();
      }
    }
    
    return RepostItem(
      id: snapshot.id,
      event: event,
      reposterProfile: reposterProfile,
      comment: data['comment'] as String?,
      repostTime: parseTimestamp(data['repostTime']),
      type: RepostContentTypeExtension.fromString(data['type'] as String?),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
    );
  }
  
  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'eventId': event.id,
      'reposterId': reposterProfile.id,
      'comment': comment,
      'repostTime': Timestamp.fromDate(repostTime),
      'type': type.toShortString(),
      'likeCount': likeCount,
    };
  }
  
  /// Create a copy with modified fields
  RepostItem copyWith({
    String? id,
    Event? event,
    UserProfile? reposterProfile,
    String? comment,
    DateTime? repostTime,
    RepostContentType? type,
    int? likeCount,
  }) {
    return RepostItem(
      id: id ?? this.id,
      event: event ?? this.event,
      reposterProfile: reposterProfile ?? this.reposterProfile,
      comment: comment ?? this.comment,
      repostTime: repostTime ?? this.repostTime,
      type: type ?? this.type,
      likeCount: likeCount ?? this.likeCount,
    );
  }
} 