import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Enum representing the different states of an event
enum EventState {
  /// Event is still being edited and not visible in feeds
  draft,
  
  /// Event is published and visible in feeds
  published,
  
  /// Event is currently happening
  live,
  
  /// Event has finished but is still in engagement window
  completed,
  
  /// Event is archived and only available in search
  archived,
}

/// Service to manage event state transitions based on temporal logic
class EventStateManager {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  
  /// Constructor
  EventStateManager({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance;
  
  /// Determine the state of an event based on its timestamps
  EventLifecycleState getEventState(Event event) {
    // Use the event's built-in currentState getter which has the same logic
    return event.currentState;
  }
  
  /// Check if the current user can edit an event
  Future<bool> canEditEvent(String eventId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = Event.fromMap({...eventDoc.data()!, 'id': eventId});
      
      // Use the event's built-in isEditableBy method
      return event.isEditableBy(user.uid);
    } catch (e) {
      debugPrint('Error checking edit permissions: $e');
      return false;
    }
  }
  
  /// Check if a specific field can be edited based on event state
  Future<bool> canEditField(String eventId, String fieldName) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      final eventDoc = await _firestore.collection('events').doc(eventId).get();
      if (!eventDoc.exists) return false;
      
      final event = Event.fromMap({...eventDoc.data()!, 'id': eventId});
      
      // Check if the user is an admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isAdmin = userDoc.data()?['role'] == 'admin';
      
      if (isAdmin) return true; // Admins can edit any field
      
      // Use the event's built-in canEditField method
      return event.canEditField(fieldName, user.uid);
    } catch (e) {
      debugPrint('Error checking field edit permissions: $e');
      return false;
    }
  }
  
  /// Update event state based on time (used by scheduled jobs)
  Future<void> updateEventStates() async {
    try {
      final now = DateTime.now();
      
      // Find events that need to transition from published to live
      final publishedToLiveQuery = await _firestore.collection('events')
          .where('published', isEqualTo: true)
          .where('startDate', isLessThanOrEqualTo: now)
          .where('state', isEqualTo: EventLifecycleState.published.name)
          .get();
      
      // Find events that need to transition from live to completed
      final liveToCompletedQuery = await _firestore.collection('events')
          .where('state', isEqualTo: EventLifecycleState.live.name)
          .where('endDate', isLessThanOrEqualTo: now)
          .get();
      
      // Find events that need to transition from completed to archived
      final completedToArchivedQuery = await _firestore.collection('events')
          .where('state', isEqualTo: EventLifecycleState.completed.name)
          .where('endDate', isLessThanOrEqualTo: now.subtract(const Duration(hours: 12)))
          .get();
      
      // Batch updates for performance
      final batch = _firestore.batch();
      
      // Process published to live transitions
      for (final doc in publishedToLiveQuery.docs) {
        batch.update(doc.reference, {
          'state': EventLifecycleState.live.name,
          'stateUpdatedAt': FieldValue.serverTimestamp(),
          'stateHistory': FieldValue.arrayUnion([{
            'state': EventLifecycleState.live.name,
            'timestamp': Timestamp.now().millisecondsSinceEpoch,
            'transitionType': 'automatic',
          }]),
        });
      }
      
      // Process live to completed transitions
      for (final doc in liveToCompletedQuery.docs) {
        batch.update(doc.reference, {
          'state': EventLifecycleState.completed.name,
          'stateUpdatedAt': FieldValue.serverTimestamp(),
          'stateHistory': FieldValue.arrayUnion([{
            'state': EventLifecycleState.completed.name,
            'timestamp': Timestamp.now().millisecondsSinceEpoch,
            'transitionType': 'automatic',
          }]),
        });
      }
      
      // Process completed to archived transitions
      for (final doc in completedToArchivedQuery.docs) {
        batch.update(doc.reference, {
          'state': EventLifecycleState.archived.name,
          'stateUpdatedAt': FieldValue.serverTimestamp(),
          'stateHistory': FieldValue.arrayUnion([{
            'state': EventLifecycleState.archived.name,
            'timestamp': Timestamp.now().millisecondsSinceEpoch,
            'transitionType': 'automatic',
          }]),
        });
      }
      
      // Commit all the updates
      await batch.commit();
      
      debugPrint('Event states updated: ${publishedToLiveQuery.docs.length} to live, '
                '${liveToCompletedQuery.docs.length} to completed, '
                '${completedToArchivedQuery.docs.length} to archived');
    } catch (e) {
      debugPrint('Error updating event states: $e');
    }
  }
  
  /// Manually transition an event to a different state (admin function)
  Future<bool> transitionEventState(String eventId, EventLifecycleState targetState) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if user is admin
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final isAdmin = userDoc.data()?['role'] == 'admin';
      
      if (!isAdmin) {
        debugPrint('Only admins can manually transition event states');
        return false;
      }
      
      // Update the event state
      await _firestore.collection('events').doc(eventId).update({
        'state': targetState.name,
        'stateUpdatedAt': FieldValue.serverTimestamp(),
        'stateHistory': FieldValue.arrayUnion([{
          'state': targetState.name,
          'timestamp': Timestamp.now().millisecondsSinceEpoch,
          'updatedBy': user.uid,
          'transitionType': 'manual',
        }]),
      });
      
      return true;
    } catch (e) {
      debugPrint('Error transitioning event state: $e');
      return false;
    }
  }
} 