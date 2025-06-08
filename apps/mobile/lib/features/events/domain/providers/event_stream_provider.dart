import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// Provider that streams a single event in real-time
final singleEventStreamProvider = StreamProvider.family<Event, String>((ref, eventId) {
  debugPrint('🔴 SingleEventStreamProvider: Setting up stream for event $eventId');
  
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('events')
      .doc(eventId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) {
          throw Exception('Event does not exist');
        }

        final data = snapshot.data()!;
        final event = Event.fromJson(data);
        
        // Emit an event update notification via AppEventBus
        AppEventBus().emit(
          EventUpdatedEvent(
            eventId: eventId,
            updates: data,
          ),
        );
        
        return event;
      });
});

/// Provider that streams all events for a space in real-time
final spaceEventsStreamProvider = StreamProvider.family<List<Event>, String>((ref, spaceId) {
  debugPrint('🔴 SpaceEventsStreamProvider: Setting up stream for space $spaceId');
  
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('events')
      .where('spaceId', isEqualTo: spaceId)
      .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('endDate', descending: false)
      .limit(20)
      .snapshots()
      .map((snapshot) {
        final events = snapshot.docs.map((doc) {
          final data = doc.data();
          return Event.fromJson(data);
        }).toList();
        
        return events;
      });
});

/// Provider that streams events a user is attending in real-time
final userAttendingEventsStreamProvider = StreamProvider.family<List<Event>, String>((ref, userId) {
  debugPrint('🔴 UserAttendingEventsStreamProvider: Setting up stream for user $userId');
  
  final firestore = FirebaseFirestore.instance;
  
  return firestore
      .collection('events')
      .where('attendees', arrayContains: userId)
      .where('endDate', isGreaterThan: Timestamp.fromDate(DateTime.now()))
      .orderBy('endDate', descending: false)
      .limit(50) 
      .snapshots()
      .map((snapshot) {
        final events = snapshot.docs.map((doc) {
          final data = doc.data();
          return Event.fromJson(data);
        }).toList();
        
        return events;
      });
}); 