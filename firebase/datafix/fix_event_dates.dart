import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// This script fixes event dates in Firestore by ensuring all date fields
/// are properly stored as Firestore Timestamps instead of strings.
/// 
/// The issue occurs when events are created with string dates instead of 
/// Timestamp objects, causing comparison and sorting issues in queries.
void main() async {
  // Initialize Flutter for Firebase
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  
  print('🔧 Starting event date fix process...');
  await fixEventDates();
  print('✅ Event date fix process completed!');
}

/// Fixes event dates in the Firestore database
Future<void> fixEventDates() async {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  try {
    // Get all events from the collection
    print('📋 Fetching all events from Firestore...');
    final QuerySnapshot eventsSnapshot = await firestore.collection('events').get();
    print('🔍 Found ${eventsSnapshot.docs.length} events to process');
    
    // Track statistics
    int totalProcessed = 0;
    int totalFixed = 0;
    
    // Process each event
    for (final DocumentSnapshot doc in eventsSnapshot.docs) {
      final String eventId = doc.id;
      final Map<String, dynamic> eventData = doc.data() as Map<String, dynamic>;
      
      bool needsUpdate = false;
      final Map<String, dynamic> updatedData = {};
      
      // Check start date
      if (eventData['startDate'] != null && eventData['startDate'] is! Timestamp) {
        try {
          final startDate = _parseDate(eventData['startDate']);
          if (startDate != null) {
            updatedData['startDate'] = Timestamp.fromDate(startDate);
            needsUpdate = true;
          }
        } catch (e) {
          print('❌ Error parsing startDate for event $eventId: ${eventData['startDate']}');
        }
      }
      
      // Check end date
      if (eventData['endDate'] != null && eventData['endDate'] is! Timestamp) {
        try {
          final endDate = _parseDate(eventData['endDate']);
          if (endDate != null) {
            updatedData['endDate'] = Timestamp.fromDate(endDate);
            needsUpdate = true;
          }
        } catch (e) {
          print('❌ Error parsing endDate for event $eventId: ${eventData['endDate']}');
        }
      }
      
      // Check last modified date
      if (eventData['lastModified'] != null && eventData['lastModified'] is! Timestamp) {
        try {
          final lastModified = _parseDate(eventData['lastModified']);
          if (lastModified != null) {
            updatedData['lastModified'] = Timestamp.fromDate(lastModified);
            needsUpdate = true;
          }
        } catch (e) {
          print('❌ Error parsing lastModified for event $eventId: ${eventData['lastModified']}');
        }
      }
      
      // Check state updated at date
      if (eventData['stateUpdatedAt'] != null && eventData['stateUpdatedAt'] is! Timestamp) {
        try {
          final stateUpdatedAt = _parseDate(eventData['stateUpdatedAt']);
          if (stateUpdatedAt != null) {
            updatedData['stateUpdatedAt'] = Timestamp.fromDate(stateUpdatedAt);
            needsUpdate = true;
          }
        } catch (e) {
          print('❌ Error parsing stateUpdatedAt for event $eventId: ${eventData['stateUpdatedAt']}');
        }
      }
      
      // Update state history timestamps if needed
      if (eventData['stateHistory'] != null && eventData['stateHistory'] is List) {
        final List<dynamic> history = eventData['stateHistory'] as List<dynamic>;
        bool historyChanged = false;
        final List<Map<String, dynamic>> updatedHistory = [];
        
        for (final entry in history) {
          if (entry is Map<String, dynamic>) {
            final Map<String, dynamic> updatedEntry = Map<String, dynamic>.from(entry);
            
            if (entry['timestamp'] != null && entry['timestamp'] is! Timestamp) {
              try {
                final timestamp = _parseDate(entry['timestamp']);
                if (timestamp != null) {
                  updatedEntry['timestamp'] = Timestamp.fromDate(timestamp);
                  historyChanged = true;
                }
              } catch (e) {
                print('❌ Error parsing history timestamp for event $eventId: ${entry['timestamp']}');
              }
            }
            
            updatedHistory.add(updatedEntry);
          } else {
            updatedHistory.add(entry as Map<String, dynamic>);
          }
        }
        
        if (historyChanged) {
          updatedData['stateHistory'] = updatedHistory;
          needsUpdate = true;
        }
      }
      
      // Update event if needed
      if (needsUpdate) {
        try {
          await firestore.collection('events').doc(eventId).update(updatedData);
          totalFixed++;
          print('✅ Fixed dates for event $eventId');
        } catch (e) {
          print('❌ Error updating event $eventId: $e');
        }
      }
      
      totalProcessed++;
      if (totalProcessed % 10 == 0) {
        print('🔄 Progress: $totalProcessed/${eventsSnapshot.docs.length} events processed');
      }
    }
    
    print('📊 Summary: Fixed dates in $totalFixed/${eventsSnapshot.docs.length} events');
  } catch (e) {
    print('❌ Error fixing event dates: $e');
  }
}

/// Parse a date from various formats
DateTime? _parseDate(dynamic dateValue) {
  if (dateValue == null) return null;
  
  if (dateValue is Timestamp) {
    return dateValue.toDate();
  } else if (dateValue is String) {
    // Try parsing as ISO 8601
    try {
      return DateTime.parse(dateValue);
    } catch (_) {
      // Try other date formats
      final formats = [
        'yyyy-MM-dd HH:mm:ss',
        'yyyy-MM-dd HH:mm',
        'yyyy-MM-dd',
        'MM/dd/yyyy HH:mm:ss',
        'MM/dd/yyyy HH:mm',
        'MM/dd/yyyy',
      ];
      
      for (final format in formats) {
        try {
          final parser = DateFormat(format);
          return parser.parse(dateValue);
        } catch (_) {
          // Try next format
        }
      }
    }
  } else if (dateValue is int) {
    // Assume milliseconds since epoch
    return DateTime.fromMillisecondsSinceEpoch(dateValue);
  } else if (dateValue is Map<String, dynamic> && 
             dateValue['seconds'] != null && 
             dateValue['nanoseconds'] != null) {
    // Handle Firestore Timestamp object format
    final seconds = dateValue['seconds'] as int;
    final nanoseconds = dateValue['nanoseconds'] as int;
    return DateTime.fromMicrosecondsSinceEpoch(
      seconds * 1000000 + (nanoseconds ~/ 1000)
    );
  }
  
  // Could not parse date
  return null;
} 