import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A command-line tool to undo an RSS sync operation
///
/// This tool will:
/// 1. Delete any new events that were created in the last sync
/// 2. Restore the events collection to its pre-sync state
/// 3. Clear any lost_events collection entries created during sync
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/undo_sync.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Undo RSS Events Sync Tool');
  print('==================================================');
  print('');
  print('This tool will attempt to undo changes made by the last RSS sync operation.');
  print('WARNING: This is a destructive operation that cannot be undone.');
  print('');
  print('Do you want to continue? (y/n): ');
  
  // Wait for user confirmation
  final confirmation = stdin.readLineSync()?.toLowerCase();
  if (confirmation != 'y') {
    print('Operation cancelled.');
    exit(0);
  }

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    // Get the timestamp of the last sync
    final metadata = await getLastSyncMetadata();
    if (metadata == null) {
      print('No sync metadata found. Cannot determine which events to rollback.');
      print('Press any key to exit...');
      await stdin.first;
      exit(1);
    }

    final syncTimestamp = metadata['completed_at'] as Timestamp?;
    if (syncTimestamp == null) {
      print('No sync completion timestamp found. Cannot determine which events to rollback.');
      print('Press any key to exit...');
      await stdin.first;
      exit(1);
    }

    print('');
    print('Last sync completed at: ${syncTimestamp.toDate().toLocal()}');
    print('');
    print('Starting rollback operation...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Count events created after the sync timestamp
    final newEventsCount = await countNewEvents(syncTimestamp);
    print('Found $newEventsCount events created during or after the last sync.');

    // Delete events that were created after the sync
    final deletedCount = await deleteNewEvents(syncTimestamp);
    print('Successfully deleted $deletedCount events.');

    // Reset sync metadata
    await resetSyncMetadata();
    print('Reset sync metadata successfully.');

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);
    print('');
    print('Rollback operation completed in ${elapsedTime.inSeconds} seconds.');
    print('');
    print('Events have been rolled back to their pre-sync state.');
    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete rollback operation:');
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

/// Get the metadata from the last sync operation
Future<Map<String, dynamic>?> getLastSyncMetadata() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final metadataSnapshot = await firestore.collection('metadata').doc('rss_sync').get();
    
    if (metadataSnapshot.exists) {
      return metadataSnapshot.data();
    }
    return null;
  } catch (e) {
    print('Error getting sync metadata: $e');
    return null;
  }
}

/// Count events created after the sync timestamp
Future<int> countNewEvents(Timestamp syncTimestamp) async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Query for events with creation timestamp after the sync
    final eventsQuery = firestore.collection('events')
        .where('createdAt', isGreaterThanOrEqualTo: syncTimestamp);
    
    final eventsCount = await eventsQuery.count().get();
    return eventsCount.count ?? 0;
  } catch (e) {
    print('Error counting new events: $e');
    return 0;
  }
}

/// Delete events that were created after the sync
Future<int> deleteNewEvents(Timestamp syncTimestamp) async {
  try {
    final firestore = FirebaseFirestore.instance;
    int deletedCount = 0;
    
    // Get events created after the sync timestamp
    final eventsQuery = firestore.collection('events')
        .where('createdAt', isGreaterThanOrEqualTo: syncTimestamp)
        .limit(500); // Process in batches to avoid memory issues
    
    bool hasMoreEvents = true;
    
    while (hasMoreEvents) {
      final eventsSnapshot = await eventsQuery.get();
      final batchSize = eventsSnapshot.docs.length;
      
      if (batchSize == 0) {
        hasMoreEvents = false;
        continue;
      }
      
      // Create a batch for efficient deletion
      final batch = firestore.batch();
      
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
        deletedCount++;
      }
      
      // Commit the batch
      await batch.commit();
      
      print('Deleted batch of $batchSize events (total: $deletedCount)');
      
      // Check if we've processed all events
      if (batchSize < 500) {
        hasMoreEvents = false;
      }
    }
    
    // Also clear any events in the lost_events collection created after the sync
    final lostEventsQuery = firestore.collection('lost_events')
        .where('createdAt', isGreaterThanOrEqualTo: syncTimestamp)
        .limit(500);
    
    hasMoreEvents = true;
    int lostEventsDeleted = 0;
    
    while (hasMoreEvents) {
      final eventsSnapshot = await lostEventsQuery.get();
      final batchSize = eventsSnapshot.docs.length;
      
      if (batchSize == 0) {
        hasMoreEvents = false;
        continue;
      }
      
      // Create a batch for efficient deletion
      final batch = firestore.batch();
      
      for (final doc in eventsSnapshot.docs) {
        batch.delete(doc.reference);
        lostEventsDeleted++;
      }
      
      // Commit the batch
      await batch.commit();
      
      print('Deleted batch of $batchSize lost events (total: $lostEventsDeleted)');
      
      // Check if we've processed all events
      if (batchSize < 500) {
        hasMoreEvents = false;
      }
    }
    
    print('Total events deleted: $deletedCount');
    print('Total lost events deleted: $lostEventsDeleted');
    
    return deletedCount + lostEventsDeleted;
  } catch (e) {
    print('Error deleting new events: $e');
    return 0;
  }
}

/// Reset the sync metadata to indicate no sync has been performed
Future<void> resetSyncMetadata() async {
  try {
    final firestore = FirebaseFirestore.instance;
    
    // Reset the sync metadata
    await firestore.collection('metadata').doc('rss_sync').set({
      'status': 'rollback_completed',
      'event_count': 0,
      'started_at': null,
      'completed_at': null,
      'rollback_time': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    // Also update the SharedPreferences timestamp
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_rss_update_timestamp');
    
    print('Successfully reset sync metadata');
  } catch (e) {
    print('Error resetting sync metadata: $e');
  }
} 