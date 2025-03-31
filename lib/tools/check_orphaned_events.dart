import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A command-line tool to check for orphaned events
///
/// This tool will:
/// 1. Find events in the main events collection without a corresponding space
/// 2. Find events in the lost_events collection
/// 3. Report statistics on these orphaned events
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/check_orphaned_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Check for Orphaned Events Tool');
  print('==================================================');
  print('');
  print('This tool will check for events without an associated space.');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');
    
    print('');
    print('Starting orphaned events check...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Check for orphaned events in the main events collection
    final orphanedStats = await checkOrphanedEvents();
    
    // Check for events in the lost_events collection
    final lostEventsCount = await countLostEvents();
    
    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);
    
    print('');
    print('Orphaned events check completed in ${elapsedTime.inSeconds} seconds.');
    print('');
    print('RESULTS:');
    print('----------------------------------------');
    print('Events in main collection: ${orphanedStats['total']}');
    print('Events with spaces: ${orphanedStats['with_space']}');
    print('Events without spaces: ${orphanedStats['without_space']}');
    print('Events missing organizer data: ${orphanedStats['missing_organizer']}');
    print('');
    print('Events in lost_events collection: $lostEventsCount');
    print('----------------------------------------');
    
    // Provide a recommendation
    print('');
    if ((orphanedStats['without_space'] ?? 0) > 0 || lostEventsCount > 0) {
      print('RECOMMENDATION:');
      print('There are events without assigned spaces. You should run:');
      print('flutter run -d windows lib/tools/migrate_lost_events.dart');
      print('to attempt to create spaces for these events.');
    } else {
      print('All events appear to be properly assigned to spaces.');
    }
    
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete check:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(1);
  }
}

/// Check for orphaned events in the main events collection
Future<Map<String, int>> checkOrphanedEvents() async {
  final stats = {
    'total': 0,
    'with_space': 0,
    'without_space': 0,
    'missing_organizer': 0,
  };
  
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Fetching events from main collection...');
    
    // Query for all events in the main collection
    final eventsQuery = firestore.collection('events').limit(1000);
    bool hasMoreEvents = true;
    
    while (hasMoreEvents) {
      final eventsSnapshot = await eventsQuery.get();
      final batchSize = eventsSnapshot.docs.length;
      
      if (batchSize == 0) {
        hasMoreEvents = false;
        continue;
      }
      
      stats['total'] = stats['total']! + batchSize;
      
      // Check each event for space association
      for (final doc in eventsSnapshot.docs) {
        final data = doc.data();
        
        // Check if event has organizer information
        if (!data.containsKey('organizerName') || data['organizerName'] == null || data['organizerName'] == '') {
          stats['missing_organizer'] = stats['missing_organizer']! + 1;
          stats['without_space'] = stats['without_space']! + 1;
          continue;
        }
        
        final organizerName = data['organizerName'] as String;
        final spaceId = _generateSpaceId(organizerName);
        
        // Look up the space ID in all possible collections
        final spaceExists = await _checkSpaceExists(firestore, spaceId);
        
        if (spaceExists) {
          stats['with_space'] = stats['with_space']! + 1;
        } else {
          stats['without_space'] = stats['without_space']! + 1;
          
          // Print sample of orphaned events
          if (stats['without_space']! <= 5) {
            print('Orphaned event: ${doc.id} - "${data['title']}" by "${organizerName}"');
          }
        }
      }
      
      print('Processed ${stats['total']} events, found ${stats['without_space']} orphaned...');
      
      // If we got less than the limit, we've run out of events
      if (batchSize < 1000) {
        hasMoreEvents = false;
      } else {
        // Use the last document as a starting point for the next query
        final lastDoc = eventsSnapshot.docs.last;
        eventsQuery.startAfterDocument(lastDoc);
      }
    }
    
    return stats;
  } catch (e) {
    print('Error checking orphaned events: $e');
    return stats;
  }
}

/// Count events in the lost_events collection
Future<int> countLostEvents() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    print('Counting events in lost_events collection...');
    
    final lostEventsCount = await firestore.collection('lost_events').count().get();
    return lostEventsCount.count ?? 0;
  } catch (e) {
    print('Error counting lost events: $e');
    return 0;
  }
}

/// Generate a space ID from organizer name
String _generateSpaceId(String organizerName) {
  // Normalize the name (lowercase, remove special chars)
  final normalized = organizerName
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');

  return 'space_$normalized';
}

/// Check if a space exists in any of the possible collections
Future<bool> _checkSpaceExists(FirebaseFirestore firestore, String spaceId) async {
  try {
    // Check all space type collections
    for (final spaceType in [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ]) {
      final spaceRef = firestore
          .collection('spaces')
          .doc(spaceType)
          .collection('spaces')
          .doc(spaceId);
      
      final spaceDoc = await spaceRef.get();
      if (spaceDoc.exists) {
        return true;
      }
    }
    
    // Also check the root spaces collection (legacy structure)
    final rootSpaceRef = firestore.collection('spaces').doc(spaceId);
    final rootSpaceDoc = await rootSpaceRef.get();
    
    return rootSpaceDoc.exists;
  } catch (e) {
    print('Error checking space existence: $e');
    return false;
  }
} 