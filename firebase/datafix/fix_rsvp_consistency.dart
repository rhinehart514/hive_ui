import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// This script ensures RSVP data consistency between:
/// - events/{eventId}/attendees collection
/// - users/{userId}/rsvps collection
/// 
/// The issue occurs when RSVP data becomes inconsistent due to failed transactions
/// or other sync issues between the collections.
void main() async {
  // Initialize Flutter for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🔧 Starting RSVP consistency fix process...');
  await fixRsvpConsistency();
  print('✅ RSVP consistency fix process completed!');
}

/// Fixes RSVP data consistency between events and users collections
Future<void> fixRsvpConsistency() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // Get all events
    print('📋 Fetching all events from Firestore...');
    final QuerySnapshot eventsSnapshot = await firestore.collection('events').get();
    print('🔍 Found ${eventsSnapshot.docs.length} events to process');
    
    // Track statistics
    int totalEvents = eventsSnapshot.docs.length;
    int processedEvents = 0;
    int totalRsvpsFixed = 0;
    int totalMissingEventRsvps = 0;
    int totalMissingUserRsvps = 0;
    
    // Process each event
    for (final DocumentSnapshot eventDoc in eventsSnapshot.docs) {
      final String eventId = eventDoc.id;
      final Map<String, dynamic> eventData = eventDoc.data() as Map<String, dynamic>;
      
      print('🔍 Processing event: $eventId - ${eventData['title'] ?? 'Unknown Title'}');
      
      // Get all attendees for this event
      final QuerySnapshot attendeesSnapshot = 
          await firestore.collection('events').doc(eventId).collection('attendees').get();
      
      print('  - Found ${attendeesSnapshot.docs.length} attendees for event $eventId');
      
      // Process each attendee
      for (final DocumentSnapshot attendeeDoc in attendeesSnapshot.docs) {
        final String userId = attendeeDoc.id;
        final Map<String, dynamic> attendeeData = attendeeDoc.data() as Map<String, dynamic>;
        
        // Check if the user has a corresponding RSVP entry
        final DocumentSnapshot userRsvpDoc = 
            await firestore.collection('users').doc(userId).collection('rsvps').doc(eventId).get();
        
        if (!userRsvpDoc.exists) {
          // User is missing the RSVP entry, create it
          print('  ⚠️ User $userId is missing RSVP entry for event $eventId, creating...');
          
          try {
            await firestore.collection('users').doc(userId).collection('rsvps').doc(eventId).set({
              'status': attendeeData['status'] ?? 'going',
              'timestamp': attendeeData['timestamp'] ?? FieldValue.serverTimestamp(),
              'eventId': eventId,
              'eventName': eventData['title'] ?? '',
              'eventStartDate': eventData['startDate'],
              'eventLocation': eventData['location'] ?? {}
            });
            
            totalMissingUserRsvps++;
            totalRsvpsFixed++;
            print('  ✅ Created missing user RSVP for user $userId on event $eventId');
          } catch (e) {
            print('  ❌ Error creating RSVP for user $userId: $e');
          }
        } else {
          // RSVP exists but may need status update
          final Map<String, dynamic> userRsvpData = userRsvpDoc.data() as Map<String, dynamic>;
          
          if (userRsvpData['status'] != attendeeData['status']) {
            print('  ⚠️ RSVP status mismatch for user $userId on event $eventId');
            print('    - Event attendee status: ${attendeeData['status']}');
            print('    - User RSVP status: ${userRsvpData['status']}');
            
            try {
              // Update user RSVP to match event attendee status
              await firestore.collection('users').doc(userId).collection('rsvps').doc(eventId).update({
                'status': attendeeData['status']
              });
              
              totalRsvpsFixed++;
              print('  ✅ Fixed RSVP status for user $userId on event $eventId');
            } catch (e) {
              print('  ❌ Error updating RSVP status for user $userId: $e');
            }
          }
        }
      }
      
      // Now check for users who have RSVPs to this event but aren't in the attendees list
      final QuerySnapshot allUsersSnapshot = await firestore.collection('users').get();
      
      for (final DocumentSnapshot userDoc in allUsersSnapshot.docs) {
        final String userId = userDoc.id;
        
        // Check if this user has an RSVP for the current event
        final DocumentSnapshot userRsvpDoc = 
            await firestore.collection('users').doc(userId).collection('rsvps').doc(eventId).get();
        
        if (userRsvpDoc.exists) {
          // Check if user is in the event's attendees
          final DocumentSnapshot eventAttendeeDoc = 
              await firestore.collection('events').doc(eventId).collection('attendees').doc(userId).get();
          
          if (!eventAttendeeDoc.exists) {
            final Map<String, dynamic> userRsvpData = userRsvpDoc.data() as Map<String, dynamic>;
            
            print('  ⚠️ User $userId has RSVP for event $eventId but is not in attendees list');
            
            try {
              // Add user to event attendees
              await firestore.collection('events').doc(eventId).collection('attendees').doc(userId).set({
                'status': userRsvpData['status'] ?? 'going',
                'timestamp': userRsvpData['timestamp'] ?? FieldValue.serverTimestamp(),
                'userId': userId
              });
              
              totalMissingEventRsvps++;
              totalRsvpsFixed++;
              print('  ✅ Added missing attendee for user $userId to event $eventId');
            } catch (e) {
              print('  ❌ Error adding attendee for user $userId: $e');
            }
          }
        }
      }
      
      processedEvents++;
      print('🔄 Progress: $processedEvents/$totalEvents events processed');
    }
    
    print('📊 Summary:');
    print('  - Total events processed: $totalEvents');
    print('  - Total RSVPs fixed: $totalRsvpsFixed');
    print('  - Missing event attendees created: $totalMissingEventRsvps');
    print('  - Missing user RSVPs created: $totalMissingUserRsvps');
    
  } catch (e) {
    print('❌ Error fixing RSVP consistency: $e');
  }
} 