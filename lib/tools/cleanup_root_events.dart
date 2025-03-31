import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up the original events collection
/// This should be run ONLY after:
/// 1. Migrating events to spaces
/// 2. Cleaning up spaces that only have events
///
/// Run with: flutter run -d windows lib/tools/cleanup_root_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Clean Up Original Events Collection');
  print('==================================================');
  print('');
  print('*** WARNING: This utility will DELETE ALL documents');
  print('*** in the original events collection.');
  print('*** Only run this after confirming events are properly migrated!');
  print('');

  print('Starting in 5 seconds (CTRL+C to cancel)...');
  await Future.delayed(const Duration(seconds: 5));

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Verifying event migration before cleanup...');
    print('');

    final verified = await verifyEventMigration();

    if (!verified) {
      print('Verification failed! Aborting cleanup operation.');
      print(
          'Please ensure all events are properly migrated before running this script again.');
      print('');
      print('Exiting in 5 seconds...');
      await Future.delayed(const Duration(seconds: 5));
      exit(1);
    }

    print('');
    print('Verification successful. Proceeding with cleanup...');
    print('');

    // Final confirmation
    print('Are you ABSOLUTELY sure you want to delete ALL original events?');
    print('Type "DELETE" to confirm:');
    final confirmation = stdin.readLineSync();

    if (confirmation != 'DELETE') {
      print('Cleanup operation cancelled.');
      print('');
      print('Exiting in 3 seconds...');
      await Future.delayed(const Duration(seconds: 3));
      exit(0);
    }

    await cleanupRootEvents();

    print('');
    print('Operation completed successfully.');
    print('');
    print('Exiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete operation:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Exiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(1);
  }
}

/// Verify that events have been properly migrated
Future<bool> verifyEventMigration() async {
  final firestore = FirebaseFirestore.instance;
  final typePaths = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other',
  ];

  // Get count of original events
  final originalEventsQuery = await firestore.collection('events').get();
  final originalEventsCount = originalEventsQuery.docs.length;

  print('Original events collection contains $originalEventsCount events.');

  // Count migrated events
  int migratedEventsCount = 0;

  for (final typePath in typePaths) {
    print('Checking spaces/$typePath/spaces for migrated events...');

    try {
      // Get all spaces in this type collection
      final spacesQuery = await firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .get();

      // Count events in each space
      for (final spaceDoc in spacesQuery.docs) {
        final eventsQuery = await spaceDoc.reference.collection('events').get();
        migratedEventsCount += eventsQuery.docs.length;
      }
    } catch (e) {
      print('Error counting events in spaces/$typePath/spaces: $e');
      return false;
    }
  }

  print('');
  print('Migration verification:');
  print('- Original events: $originalEventsCount');
  print('- Migrated events: $migratedEventsCount');

  // Allow for some potential duplication or skipped events
  final ratio = migratedEventsCount / originalEventsCount;
  print('- Migration ratio: ${(ratio * 100).toStringAsFixed(1)}%');

  if (ratio < 0.95) {
    print('');
    print('VERIFICATION FAILED: Less than 95% of events were migrated.');
    print('Please check your migration process before proceeding.');
    return false;
  }

  print('');
  print('VERIFICATION PASSED: Events appear to be properly migrated.');
  return true;
}

/// Clean up the original events collection
Future<void> cleanupRootEvents() async {
  final firestore = FirebaseFirestore.instance;

  print('Deleting all events from original events collection...');
  int deletedEvents = 0;
  int batchSize = 0;
  WriteBatch batch = firestore.batch();

  try {
    final eventsQuery = await firestore.collection('events').get();

    for (final eventDoc in eventsQuery.docs) {
      batch.delete(eventDoc.reference);
      batchSize++;
      deletedEvents++;

      // Commit in batches of 500 (Firestore limit)
      if (batchSize >= 500) {
        await batch.commit();
        print('Deleted batch of $batchSize events (total: $deletedEvents)');
        batch = firestore.batch();
        batchSize = 0;
      }
    }

    // Commit any remaining deletes
    if (batchSize > 0) {
      await batch.commit();
      print('Deleted final batch of $batchSize events');
    }

    print('');
    print(
        'Successfully deleted $deletedEvents events from original collection.');
  } catch (e) {
    print('Error during deletion: $e');
    rethrow;
  }
}
