import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to migrate events from the original spaces collection
/// to the new type-specific space subcollections.
///
/// This script will:
/// 1. For each space in the type-specific subcollections (spaces/[type]/spaces/[spaceId])
/// 2. Check if there are events in the original location (spaces/[spaceId]/events)
/// 3. Move those events to the new location (spaces/[type]/spaces/[spaceId]/events)
///
/// Run with: flutter run -d windows lib/tools/migrate_events_to_typed_spaces.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Migrate Events to Typed Spaces');
  print('==================================================');
  print('');
  print('This utility will migrate events from the original spaces collection');
  print('to the new type-specific space subcollections.');
  print('');

  print('Starting in 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting event migration...');
    print('');

    await migrateEventsToTypedSpaces();

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

/// Migrate events from the original spaces collection to the new type-specific spaces
Future<void> migrateEventsToTypedSpaces() async {
  final firestore = FirebaseFirestore.instance;
  final typePaths = getTypePaths();

  int totalSpacesChecked = 0;
  int totalEventsFound = 0;
  int totalEventsMigrated = 0;
  int totalSpacesWithEvents = 0;

  // Check each type collection
  for (final typePath in typePaths) {
    print('Processing spaces in spaces/$typePath/spaces collection...');

    try {
      // Get all spaces in this type subcollection
      final spacesQuery = await firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .get();

      print(
          'Found ${spacesQuery.docs.length} spaces in spaces/$typePath/spaces');

      // Process each space
      for (final spaceDoc in spacesQuery.docs) {
        totalSpacesChecked++;
        final spaceId = spaceDoc.id;

        // Check if events exist in original location
        final originalEventsRef =
            firestore.collection('spaces').doc(spaceId).collection('events');

        final originalEvents = await originalEventsRef.get();
        final eventCount = originalEvents.docs.length;

        if (eventCount > 0) {
          print(
              'Found $eventCount events for space $spaceId in original location');
          totalEventsFound += eventCount;
          totalSpacesWithEvents++;

          // Create batch for event migration
          var batch = firestore.batch();
          int batchCount = 0;
          int eventsMigratedForSpace = 0;

          // Reference to new events collection
          final newEventsRef = firestore
              .collection('spaces')
              .doc(typePath)
              .collection('spaces')
              .doc(spaceId)
              .collection('events');

          // Migrate each event
          for (final eventDoc in originalEvents.docs) {
            final eventId = eventDoc.id;
            final eventData = eventDoc.data();

            // Create the event in the new location
            final newEventRef = newEventsRef.doc(eventId);
            batch.set(newEventRef, eventData);

            batchCount++;
            eventsMigratedForSpace++;
            totalEventsMigrated++;

            // Commit batch every 400 operations
            if (batchCount >= 400) {
              print('Committing batch of $batchCount events...');
              await batch.commit();
              batch = firestore.batch();
              batchCount = 0;
            }
          }

          // Commit any remaining operations
          if (batchCount > 0) {
            print('Committing final batch of $batchCount events...');
            await batch.commit();
          }

          print(
              'Successfully migrated $eventsMigratedForSpace events for space $spaceId');
        }
      }
    } catch (e) {
      print('Error processing spaces/$typePath/spaces: $e');
    }
  }

  // Final summary
  print('');
  print('Migration summary:');
  print('- Total spaces checked: $totalSpacesChecked');
  print('- Spaces with events: $totalSpacesWithEvents');
  print('- Total events found: $totalEventsFound');
  print('- Total events migrated: $totalEventsMigrated');

  if (totalEventsFound > 0) {
    print('');
    print('IMPORTANT: Events have been copied to the new locations.');
    print('After verifying that events are correctly migrated, you may run');
    print(
        'a cleanup script to remove the original space documents and their events.');
  }
}
