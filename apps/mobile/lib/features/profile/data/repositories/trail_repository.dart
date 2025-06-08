import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/domain/models/trail_entry.dart';

/// Repository for managing user activity trail
class TrailRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TrailRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Collection reference for trail entries
  CollectionReference get _trailCollection => _firestore.collection('trails');

  /// Get a user's trail entries
  Stream<List<TrailEntry>> getUserTrail(String userId) {
    return _trailCollection
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50) // Limit to most recent 50 activities
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => TrailEntry.fromFirestore(doc))
              .toList();
        });
  }

  /// Get the current user's trail entries
  Stream<List<TrailEntry>> getCurrentUserTrail() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value([]);
    }
    return getUserTrail(currentUser.uid);
  }

  /// Add a trail entry
  Future<void> addTrailEntry(TrailEntry entry) async {
    try {
      await _trailCollection.add(entry.toFirestore());
    } catch (e) {
      debugPrint('Error adding trail entry: $e');
      rethrow;
    }
  }

  /// Record a space join activity
  Future<void> recordSpaceJoin(String spaceId, String spaceName, String? imageUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final entry = TrailEntry(
      id: '', // Will be set by Firestore
      userId: currentUser.uid,
      timestamp: DateTime.now(),
      activityType: TrailActivityType.spaceJoin,
      title: 'Joined $spaceName',
      description: 'New space affiliation',
      relatedEntityId: spaceId,
      relatedEntityType: 'space',
      imageUrl: imageUrl,
      metadata: {
        'spaceName': spaceName,
      },
    );

    await addTrailEntry(entry);
  }

  /// Record an event attendance
  Future<void> recordEventAttendance(String eventId, String eventTitle, String? imageUrl) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final entry = TrailEntry(
      id: '', // Will be set by Firestore
      userId: currentUser.uid,
      timestamp: DateTime.now(),
      activityType: TrailActivityType.eventAttendance,
      title: 'Going to $eventTitle',
      description: 'Attending event',
      relatedEntityId: eventId,
      relatedEntityType: 'event',
      imageUrl: imageUrl,
      metadata: {
        'eventTitle': eventTitle,
      },
    );

    await addTrailEntry(entry);
  }

  /// Record a content creation
  Future<void> recordCreation(
    String contentType,
    String contentId,
    String title,
    String? imageUrl,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final entry = TrailEntry(
      id: '', // Will be set by Firestore
      userId: currentUser.uid,
      timestamp: DateTime.now(),
      activityType: TrailActivityType.creation,
      title: 'Created $title',
      description: 'New $contentType created',
      relatedEntityId: contentId,
      relatedEntityType: contentType,
      imageUrl: imageUrl,
      metadata: {
        'contentType': contentType,
        'title': title,
      },
    );

    await addTrailEntry(entry);
  }

  /// Record a signal (RSVP, boost, etc.)
  Future<void> recordSignal(
    String signalType,
    String targetId,
    String targetType,
    String targetName,
    String? imageUrl,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    String title;
    switch (signalType) {
      case 'rsvp':
        title = 'RSVPed to $targetName';
        break;
      case 'boost':
        title = 'Boosted $targetName';
        break;
      case 'share':
        title = 'Shared $targetName';
        break;
      default:
        title = 'Interacted with $targetName';
    }

    final entry = TrailEntry(
      id: '', // Will be set by Firestore
      userId: currentUser.uid,
      timestamp: DateTime.now(),
      activityType: TrailActivityType.signal,
      title: title,
      description: 'Signal: $signalType',
      relatedEntityId: targetId,
      relatedEntityType: targetType,
      imageUrl: imageUrl,
      metadata: {
        'signalType': signalType,
        'targetName': targetName,
      },
    );

    await addTrailEntry(entry);
  }

  /// Record an achievement
  Future<void> recordAchievement(
    String achievementId,
    String achievementName,
    String description,
    String? imageUrl,
  ) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final entry = TrailEntry(
      id: '', // Will be set by Firestore
      userId: currentUser.uid,
      timestamp: DateTime.now(),
      activityType: TrailActivityType.achievement,
      title: 'Earned $achievementName',
      description: description,
      relatedEntityId: achievementId,
      relatedEntityType: 'achievement',
      imageUrl: imageUrl,
      metadata: {
        'achievementName': achievementName,
      },
    );

    await addTrailEntry(entry);
  }
}

/// Provider for TrailRepository
final trailRepositoryProvider = Provider<TrailRepository>((ref) {
  return TrailRepository();
}); 