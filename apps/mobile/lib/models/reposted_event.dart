import 'package:flutter/foundation.dart';
import '../../models/event.dart';
import '../../models/user_profile.dart';
// Import needed for fromStreamData

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
    // Use repostedAt for consistency in ID generation
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

  /// Factory constructor for data coming directly from the combined stream
  /// Used in FeedRepositoryImpl.getFeedStream
  factory RepostedEvent.fromStreamData({
    required String id,
    required Event event,
    required UserProfile repostedBy,
    required DateTime repostTime, // Name matches stream data
    String? comment,
    required String repostType,
  }) {
    return RepostedEvent(
      id: id,
      event: event,
      repostedBy: repostedBy,
      repostedAt: repostTime, // Use the provided repostTime
      comment: comment,
      repostType: repostType,
      // contentType can be derived or handled elsewhere if needed
      // interactionCounts would need separate fetching/handling
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
  
  /// Create from Firestore document data (when nested data is present)
  factory RepostedEvent.fromJson(Map<String, dynamic> json) {
    // Assume nested Event and UserProfile data is present in the JSON
    if (json['eventData'] == null || json['repostedByData'] == null) {
        throw const FormatException("Missing nested eventData or repostedByData in RepostedEvent JSON");
    }
    
    // Extract nested data
    final Event event = Event.fromJson(json['eventData'] as Map<String, dynamic>);
    final UserProfile repostedBy = UserProfile.fromJson(json['repostedByData'] as Map<String, dynamic>);
    
    // Extract other fields
    final DateTime repostedAt = DateTime.parse(json['repostedAt'] as String);
    final String? comment = json['comment'] as String?;
    final String repostType = json['repostType'] as String;
    // Use 'id' if present, otherwise construct one (though ideally ID should always be in the document)
    final String id = json['id'] as String? ?? 'repost_${repostedAt.millisecondsSinceEpoch}_${repostedBy.id}_${event.id}'; 

    return RepostedEvent(
      event: event,
      repostedBy: repostedBy,
      repostedAt: repostedAt,
      comment: comment,
      repostType: repostType,
      id: id,
    );
  }
} 