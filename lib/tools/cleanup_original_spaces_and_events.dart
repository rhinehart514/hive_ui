import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up original space documents and their events
/// after successful migration to the type-specific collections.
///
/// This script will:
/// 1. Identify all space documents in the root spaces collection
/// 2. Delete their events subcollections
/// 3. Delete the space documents themselves
///
/// IMPORTANT: Only run this after verifying that events have been successfully
/// migrated to the new type-specific space collections!
///
/// Run with: flutter run -d windows lib/tools/cleanup_original_spaces_and_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Clean Up Original Spaces and Events');
  print('==================================================');
  print('');
  print('*** WARNING: This utility will DELETE original space documents');
  print('*** and their events from the root spaces collection.');
  print('*** Only run this after verifying successful migration!');
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
    print('Starting cleanup of original spaces and events...');
    print('');

    await cleanupOriginalSpacesAndEvents();

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

/// Get all type paths for spaces
List<String> getTypePaths() {
  return [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other',
  ];
}

/// Clean up original spaces and their events
Future<void> cleanupOriginalSpacesAndEvents() async {
  final firestore = FirebaseFirestore.instance;
  final typePaths = getTypePaths();

  // Fetch all spaces from the root collection
  print('Fetching spaces from root collection...');
  final spacesQuery = await firestore.collection('spaces').get();

  // Filter out type documents
  final spaceDocs = spacesQuery.docs
      .where(
          (doc) => !typePaths.contains(doc.id) && doc.id.startsWith('space_'))
      .toList();

  print('Found ${spaceDocs.length} space documents in root collection');

  int totalSpacesDeleted = 0;
  int totalEventsDeleted = 0;
  int batchCount = 0;
  var batch = firestore.batch();

  // Process each space
  for (final spaceDoc in spaceDocs) {
    final spaceId = spaceDoc.id;
    print('Processing space: $spaceId');

    // First, delete all events in this space
    try {
      final eventsQuery = await firestore
          .collection('spaces')
          .doc(spaceId)
          .collection('events')
          .get();

      final eventsCount = eventsQuery.docs.length;

      if (eventsCount > 0) {
        print('Deleting $eventsCount events for space $spaceId');

        // Delete each event
        for (final eventDoc in eventsQuery.docs) {
          batch.delete(eventDoc.reference);
          totalEventsDeleted++;
          batchCount++;

          // Commit batch every 400 operations
          if (batchCount >= 400) {
            print('Committing batch of $batchCount operations...');
            await batch.commit();
            batch = firestore.batch();
            batchCount = 0;
          }
        }
      }
    } catch (e) {
      print('Error deleting events for space $spaceId: $e');
    }

    // Delete the space document itself
    batch.delete(spaceDoc.reference);
    totalSpacesDeleted++;
    batchCount++;

    // Commit batch every 400 operations
    if (batchCount >= 400) {
      print('Committing batch of $batchCount operations...');
      await batch.commit();
      batch = firestore.batch();
      batchCount = 0;
    }
  }

  // Commit any remaining operations
  if (batchCount > 0) {
    print('Committing final batch of $batchCount operations...');
    await batch.commit();
  }

  // Final summary
  print('');
  print('Cleanup summary:');
  print('- Total spaces deleted: $totalSpacesDeleted');
  print('- Total events deleted: $totalEventsDeleted');
}
