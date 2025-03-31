import 'package:flutter/foundation.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';

/// Model representing a reposted event
@immutable
class RepostedEvent {
  /// The original event
  final Event event;
  
  /// The user who reposted the event
  final UserProfile repostedBy;
  
  /// The timestamp when the event was reposted
  final DateTime repostedAt;
  
  /// Optional comment added when reposting
  final String? comment;
  
  /// The type of repost (standard, quote, boost)
  final String repostType;
  
  /// Unique ID for the repost
  final String id;
  
  /// Constructor
  const RepostedEvent({
    required this.event,
    required this.repostedBy,
    required this.repostedAt,
    this.comment,
    required this.repostType,
    required this.id,
  });
  
  /// Creates a new repost with a unique ID
  factory RepostedEvent.create({
    required Event event,
    required UserProfile repostedBy,
    String? comment,
    required String repostType,
  }) {
    final now = DateTime.now();
    final id = 'repost_${now.millisecondsSinceEpoch}_${repostedBy.id}_${event.id}';
    
    return RepostedEvent(
      event: event,
      repostedBy: repostedBy,
      repostedAt: now,
      comment: comment,
      repostType: repostType,
      id: id,
    );
  }
  
  /// Convert to a map for storage
  Map<String, dynamic> toJson() {
    return {
      'eventId': event.id,
      'repostedById': repostedBy.id,
      'repostedAt': repostedAt.toIso8601String(),
      'comment': comment,
      'repostType': repostType,
      'id': id,
    };
  }
} 