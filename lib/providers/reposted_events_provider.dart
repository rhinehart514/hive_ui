import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reposted_event.dart';
import '../models/event.dart';
import '../models/user_profile.dart';
import '../models/repost_content_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Provider for storing and retrieving reposted events
final repostedEventsProvider = StateNotifierProvider<RepostedEventsNotifier, List<RepostedEvent>>((ref) {
  return RepostedEventsNotifier();
});

/// Notifier class for reposted events
class RepostedEventsNotifier extends StateNotifier<List<RepostedEvent>> {
  RepostedEventsNotifier() : super([]){
    // Initialize by loading reposted events from Firestore
    _loadRepostedEvents();
  }
  
  /// Load reposted events from Firestore
  Future<void> _loadRepostedEvents() async {
    try {
      final repostsSnapshot = await FirebaseFirestore.instance
          .collection('reposts')
          .orderBy('repostedAt', descending: true)
          .limit(20)
          .get();
      
      if (repostsSnapshot.docs.isEmpty) {
        debugPrint('No reposts found in database');
        return;
      }
      
      // Process reposts and load associated events and users
      final List<RepostedEvent> loadedReposts = [];
      
      for (final doc in repostsSnapshot.docs) {
        try {
          final data = doc.data();
          
          // Validate required fields exist
          if (!data.containsKey('eventId') || !data.containsKey('repostedById')) {
            debugPrint('Repost doc ${doc.id} missing eventId or userId');
            continue;
          }

          final eventId = data['eventId'] as String;
          final repostedById = data['repostedById'] as String;
          
          // Validate IDs are not empty
          if (eventId.isEmpty || repostedById.isEmpty) {
            debugPrint('Repost doc ${doc.id} has empty eventId or userId');
            continue;
          }

          // Get the event document
          final eventDoc = await FirebaseFirestore.instance
              .collection('events')
              .doc(eventId)
              .get();
          
          if (!eventDoc.exists) {
            debugPrint('Event $eventId not found for repost ${doc.id}');
            continue;
          }
          
          // Get the user profile document
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(repostedById)
              .get();
          
          if (!userDoc.exists) {
            debugPrint('User $repostedById not found for repost ${doc.id}');
            continue;
          }
          
          // Create Event and UserProfile objects
          final eventData = eventDoc.data()!;
          eventData['id'] = eventDoc.id;
          final event = Event.fromJson(eventData);
          
          final userData = userDoc.data() ?? {};
          final userProfile = UserProfile(
            id: userDoc.id,
            displayName: userData['displayName'] ?? 'User',
            username: userData['username'] ?? 'user_${userDoc.id.substring(0, 5)}',
            profileImageUrl: userData['profileImageUrl'],
            email: userData['email'] ?? '',
            year: userData['year'] ?? '',
            major: userData['major'] ?? '',
            residence: userData['residence'] ?? '',
            eventCount: userData['eventCount'] ?? 0,
            clubCount: userData['clubCount'] ?? 0,
            friendCount: userData['friendCount'] ?? 0,
            createdAt: _parseTimestamp(userData['createdAt']),
            updatedAt: _parseTimestamp(userData['updatedAt']),
          );
          
          // Create RepostedEvent
          final repost = RepostedEvent(
            event: event,
            repostedBy: userProfile,
            repostedAt: _parseTimestamp(data['repostedAt']),
            comment: data['comment'] as String?,
            repostType: data['repostType'] as String,
            id: doc.id,
          );
          
          loadedReposts.add(repost);
        } catch (e) {
          debugPrint('Error processing repost document: $e');
          continue;
        }
      }
      
      // Update state
      state = loadedReposts;
      debugPrint('Loaded ${loadedReposts.length} reposts from database');
    } catch (e) {
      debugPrint('Error loading reposts: $e');
    }
  }
  
  /// Add a reposted event
  Future<void> addRepost({
    required Event event,
    required UserProfile repostedBy,
    String? comment,
    required RepostContentType type,
  }) async {
    // For quote reposts, ensure we have a comment
    if (type == RepostContentType.quote && (comment == null || comment.trim().isEmpty)) {
      debugPrint('Warning: Quote repost requires comment text');
      return; // Don't create a quote repost without comment text
    }
    
    // Create a new reposted event
    final repost = RepostedEvent.create(
      event: event,
      repostedBy: repostedBy,
      comment: comment,
      repostType: type.name,
    );
    
    // Add to the state immediately for optimistic UI update
    state = [repost, ...state];
    
    // For debugging
    debugPrint('Created repost: ${type.name} with comment: $comment');
    debugPrint('Reposted event: ${event.title} by ${repostedBy.displayName}');
    
    // Save to Firestore
    try {
      await _saveRepostToBackend(repost);
      debugPrint('Successfully saved repost to database');
    } catch (e) {
      debugPrint('Error saving repost to database: $e');
      // On error, revert the state change
      state = state.where((r) => r.id != repost.id).toList();
    }
  }
  
  /// Get all reposted events
  List<RepostedEvent> getAllReposts() {
    return state;
  }
  
  /// Get reposted events by the current user
  List<RepostedEvent> getRepostsByUser(String userId) {
    return state.where((repost) => repost.repostedBy.id == userId).toList();
  }
  
  /// Check if an event has been reposted by a user
  bool isEventRepostedBy(String eventId, String userId) {
    return state.any((repost) => 
      repost.event.id == eventId && 
      repost.repostedBy.id == userId
    );
  }
  
  /// Get all events that should be shown in the feed, including reposted events
  List<Event> getEventsForFeed(List<Event> originalEvents) {
    // Extract events from reposts
    final repostedEvents = state.map((repost) => repost.event).toList();
    
    // Combine original events with reposted events
    final allEvents = [...originalEvents, ...repostedEvents];
    
    // Remove duplicates by event ID
    final Map<String, Event> uniqueEvents = {};
    for (final event in allEvents) {
      uniqueEvents[event.id] = event;
    }
    
    return uniqueEvents.values.toList();
  }
  
  /// Save repost to Firestore
  Future<void> _saveRepostToBackend(RepostedEvent repost) async {
    try {
      // Validate required fields
      if (repost.event.id.isEmpty || repost.repostedBy.id.isEmpty) {
        throw Exception('Cannot save repost: missing eventId or userId');
      }

      final repostData = {
        'eventId': repost.event.id,
        'repostedById': repost.repostedBy.id,
        'repostedAt': Timestamp.fromDate(repost.repostedAt),
        'comment': repost.comment,
        'repostType': repost.repostType,
        'contentType': repost.repostType,
        'createdAt': Timestamp.fromDate(repost.repostedAt),
      };

      // Validate all required fields are present and of correct type
      for (final entry in repostData.entries) {
        if (entry.key != 'comment' && entry.value == null) {
          throw Exception('Cannot save repost: missing required field ${entry.key}');
        }
      }

      // Verify the event actually exists in Firestore
      final eventDoc = await FirebaseFirestore.instance
          .collection('events')
          .doc(repost.event.id)
          .get();
      
      if (!eventDoc.exists) {
        throw Exception('Cannot save repost: event ${repost.event.id} does not exist');
      }
      
      // Verify the user actually exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(repost.repostedBy.id)
          .get();
      
      if (!userDoc.exists) {
        throw Exception('Cannot save repost: user ${repost.repostedBy.id} does not exist');
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('reposts')
          .doc(repost.id)
          .set(repostData);
          
      debugPrint('Successfully saved repost ${repost.id} to database');
    } catch (e) {
      debugPrint('Error in _saveRepostToBackend: $e');
      throw Exception('Failed to save repost: $e');
    }
  }
  
  /// Helper function to parse timestamp from various formats
  DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return DateTime.now(); // Fallback to current time
    }
  }
  
  void removeRepost(String eventId) {
    state = state.where((repost) => repost.event.id != eventId).toList();
  }
} 