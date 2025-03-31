import 'package:cloud_firestore/cloud_firestore.dart';

/// Helper class for space-related utilities
class SpaceHelper {
  /// Creates a complete space data structure with all required fields
  /// using provided values or defaults
  static Map<String, dynamic> createCompleteSpaceData({
    required String id,
    String? name,
    String? description,
    String? spaceType,
    List<String>? eventIds,
    List<String>? tags,
    bool isAutoCreated = true,
  }) {
    final now = FieldValue.serverTimestamp();

    // Create metrics object with defaults
    final metrics = {
      'memberCount': 0,
      'activeMembers': 0,
      'weeklyEvents': eventIds?.length ?? 0,
      'monthlyEngagements': 0,
      'engagementScore': 0.0,
      'hasNewContent': eventIds?.isNotEmpty ?? false,
      'isTrending': false,
      'isTimeSensitive': false,
      'category': 'suggested',
      'size': 'medium',
      'connectedFriends': <String>[],
      'spaceId': id,
      'lastActivity': now,
    };

    // Create the complete space data
    return {
      'id': id,
      'name': name ?? 'Space $id',
      'description': description ?? 'Auto-generated space',
      'spaceType': spaceType ?? 'other',
      'createdAt': now,
      'updatedAt': now,
      'tags': tags ?? ['auto-created'],
      'eventIds': eventIds ?? <String>[],
      'moderators': <String>[],
      'admins': <String>[],
      'relatedSpaceIds': <String>[],
      'customData': <String, dynamic>{},
      'quickActions': <String, dynamic>{},
      'isJoined': false,
      'isPrivate': false,
      'isAutoCreated': isAutoCreated,
      'metrics': metrics,
    };
  }
}
