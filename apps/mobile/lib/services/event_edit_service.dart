import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/event.dart';
import '../models/event_status.dart';
import '../utils/firebase_paths.dart';

/// Service to handle event editing and cancellation
class EventEditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Updates an existing event
  static Future<void> updateEvent(Event event) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to update an event');
    }
    
    // Verify the user has permission to edit this event
    if (event.createdBy != currentUser.uid) {
      // Check if user is an admin or co-host (this would depend on your app's logic)
      throw Exception('You do not have permission to edit this event');
    }
    
    // Update the event's last modified timestamp
    final updatedEvent = event.copyWith(
      lastModified: DateTime.now(),
    );
    
    try {
      await _firestore
          .collection(FirebasePaths.events)
          .doc(event.id)
          .update(updatedEvent.toJson());
      
      debugPrint('Event updated successfully: ${event.id}');
    } catch (e) {
      debugPrint('Error updating event: $e');
      throw Exception('Failed to update the event: $e');
    }
  }
  
  /// Cancels an event by setting its status to cancelled
  static Future<void> cancelEvent(Event event) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      throw Exception('You must be logged in to cancel an event');
    }
    
    // Verify the user has permission to cancel this event
    if (event.createdBy != currentUser.uid) {
      // Check if user is an admin or co-host (this would depend on your app's logic)
      throw Exception('You do not have permission to cancel this event');
    }
    
    // Update the event status to cancelled
    final cancelledEvent = event.copyWith(
      status: EventStatus.cancelled.value,
      lastModified: DateTime.now(),
    );
    
    try {
      await _firestore
          .collection(FirebasePaths.events)
          .doc(event.id)
          .update(cancelledEvent.toJson());
      
      debugPrint('Event cancelled successfully: ${event.id}');
      
      // If there's a space for this event, update there too
      if (event.spaceId != null) {
        await _updateEventInSpace(cancelledEvent);
      }
      
      return;
    } catch (e) {
      debugPrint('Error cancelling event: $e');
      throw Exception('Failed to cancel the event: $e');
    }
  }
  
  /// Updates an event within its associated space
  static Future<void> _updateEventInSpace(Event event) async {
    if (event.spaceId == null) return;
    
    try {
      await _firestore
          .collection(FirebasePaths.spaces)
          .doc(event.spaceId)
          .collection('events')
          .doc(event.id)
          .update(event.toJson());
      
      debugPrint('Event updated in space: ${event.spaceId}');
    } catch (e) {
      debugPrint('Error updating event in space: $e');
      // Don't throw here - consider this optional
    }
  }
  
  /// Shows a confirmation dialog for cancelling an event
  static Future<bool> showCancelConfirmation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text(
            'Cancel Event',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'Are you sure you want to cancel this event? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No, Keep Event'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Yes, Cancel Event'),
            ),
          ],
        );
      },
    );
    
    return result ?? false;
  }
} 