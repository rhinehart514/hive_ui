import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/activity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/event.dart';

/// Provider for user activity feed with Firestore integration
final userActivityProvider =
    FutureProvider.family<List<Activity>, String>((ref, String userId) async {
  try {
    debugPrint('ActivityProvider: Loading activities for user $userId');
    final firestore = FirebaseFirestore.instance;

    // Query user activities from Firestore
    final snapshot = await firestore
        .collection('user_activities')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(20) // Get the most recent 20 activities
        .get();

    if (snapshot.docs.isEmpty) {
      debugPrint('ActivityProvider: No activities found for user $userId');
      return [];
    }

    // Map Firestore documents to Activity objects
    final activities = snapshot.docs.map((doc) {
      final data = doc.data();
      return Activity(
        id: doc.id,
        type: _parseActivityType(data['type']),
        timestamp: _parseTimestamp(data['timestamp']),
        title: data['title'],
        subtitle: data['subtitle'],
        iconData: IconData(
          data['iconCode'] ?? 0xe318, // Default to event icon if missing
          fontFamily: 'MaterialIcons',
        ),
        relatedId: data['relatedId'] ?? '',
      );
    }).toList();

    debugPrint('ActivityProvider: Loaded ${activities.length} activities');
    return activities;
  } catch (e) {
    debugPrint('ActivityProvider: Error loading activities: $e');
    return [];
  }
});

// Helper method to parse activity type from string
ActivityType _parseActivityType(String? typeString) {
  if (typeString == null) return ActivityType.postCreated;

  switch (typeString) {
    case 'joinedClub':
      return ActivityType.joinedClub;
    case 'attendedEvent':
      return ActivityType.attendedEvent;
    case 'achievement':
      return ActivityType.achievement;
    case 'newFriend':
      return ActivityType.newFriend;
    case 'postCreated':
      return ActivityType.postCreated;
    default:
      return ActivityType.postCreated;
  }
}

// Helper function to parse timestamp from various formats
DateTime _parseTimestamp(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is int) {
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  } else {
    return DateTime.now(); // Fallback to current time
  }
}

/// Service for creating and managing user activities
class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _activityCollection = 'user_activities';

  /// Log a new activity for a user
  Future<void> logActivity({
    required String userId,
    required ActivityType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required String relatedId,
  }) async {
    try {
      await _firestore.collection(_activityCollection).add({
        'userId': userId,
        'type': type.toString().split('.').last,
        'timestamp': FieldValue.serverTimestamp(),
        'title': title,
        'subtitle': subtitle,
        'iconCode': icon.codePoint,
        'relatedId': relatedId,
      });

      debugPrint('ActivityService: Activity logged for user $userId');
    } catch (e) {
      debugPrint('ActivityService: Error logging activity: $e');
    }
  }

  /// Log an event attendance activity
  Future<void> logEventAttendance(String userId, Event event) async {
    await logActivity(
      userId: userId,
      type: ActivityType.attendedEvent,
      title: 'Attending event',
      subtitle: event.title,
      icon: Icons.event,
      relatedId: event.id,
    );
  }

  /// Log a new friend activity
  Future<void> logNewFriend(
      String userId, String friendName, String friendId) async {
    await logActivity(
      userId: userId,
      type: ActivityType.newFriend,
      title: 'New connection',
      subtitle: 'Connected with $friendName',
      icon: Icons.people,
      relatedId: friendId,
    );
  }

  /// Log a club joining activity
  Future<void> logClubJoined(
      String userId, String clubName, String clubId) async {
    await logActivity(
      userId: userId,
      type: ActivityType.joinedClub,
      title: 'Joined club',
      subtitle: clubName,
      icon: Icons.groups,
      relatedId: clubId,
    );
  }

  /// Log an achievement
  Future<void> logAchievement(String userId, String achievement) async {
    await logActivity(
      userId: userId,
      type: ActivityType.achievement,
      title: 'Achievement unlocked',
      subtitle: achievement,
      icon: Icons.emoji_events,
      relatedId: '',
    );
  }
}

/// Provider for the activity service
final activityServiceProvider = Provider<ActivityService>((ref) {
  return ActivityService();
});

/// Provider to track whether the profile page is viewing the current user or another user
final StateProvider<bool> isCurrentUserProfileProvider =
    StateProvider<bool>((ref) => true);
