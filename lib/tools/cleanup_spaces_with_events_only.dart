import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up spaces that have no data but have events.
/// This should be run after migrating events to spaces.
///
/// This script will:
/// 1. Check all spaces in type-specific subcollections
/// 2. Identify spaces with no useful data (empty or near-empty documents)
/// 3. Check if these spaces have events
/// 4. Delete spaces that have no data but have events (after event migration)
///
/// Run with: flutter run -d windows lib/tools/cleanup_spaces_with_events_only.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Clean Up Event-Only Spaces');
  print('==================================================');
  print('');
  print('*** WARNING: This utility will identify and delete spaces');
  print('*** that have no useful data but have events.');
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
    print('Starting cleanup of event-only spaces...');
    print('');

    await cleanupSpacesWithEventsOnly();

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

/// Check if a space document has no useful data
bool isSpaceEmpty(Map<String, dynamic> data) {
  // If it's completely empty
  if (data.isEmpty) return true;

  // List of fields that don't constitute meaningful space data
  // These might be auto-populated or system fields
  final List<String> nonSubstantiveFields = [
    'spaceType',
    'id',
    'createdAt',
    'updatedAt',
    'name',
    'slug',
    'type',
    'searchKeywords',
    'verified',
    'imageUrl',
    'color',
    'shortDescription'
  ];

  // Count how many fields with actual values this space has
  int substantiveFieldCount = 0;

  data.forEach((key, value) {
    // Skip if it's a non-substantive field
    if (nonSubstantiveFields.contains(key)) {
      return;
    }

    // Skip empty values
    if (value == null ||
        value == '' ||
        (value is List && value.isEmpty) ||
        (value is Map && value.isEmpty)) {
      return;
    }

    // This is a field with actual data
    substantiveFieldCount++;
  });

  // Consider it empty if it has 2 or fewer substantive fields
  // This is more aggressive than the previous version which only checked for presence
  return substantiveFieldCount <= 2;
}

/// Clean up spaces that have no data but have events
Future<void> cleanupSpacesWithEventsOnly() async {
  final firestore = FirebaseFirestore.instance;
  final typePaths = getTypePaths();

  int totalSpacesChecked = 0;
  int totalSpacesWithEvents = 0;
  int totalEmptySpaces = 0;
  int totalEmptySpacesWithEvents = 0;
  int totalSpacesDeleted = 0;

  // Process each type collection
  for (final typePath in typePaths) {
    print('Checking spaces/$typePath/spaces collection...');

    try {
      // Get all spaces in this type collection
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
        final spaceData = spaceDoc.data();

        // Check if space has events
        final eventsQuery = await spaceDoc.reference.collection('events').get();
        final hasEvents = eventsQuery.docs.isNotEmpty;
        final eventCount = eventsQuery.docs.length;

        if (hasEvents) {
          totalSpacesWithEvents++;
        }

        // Check if space has no useful data
        final isEmpty = isSpaceEmpty(spaceData);
        if (isEmpty) {
          totalEmptySpaces++;

          if (hasEvents) {
            totalEmptySpacesWithEvents++;

            print('\nFound space with minimal data and $eventCount events:');
            print('Path: ${spaceDoc.reference.path}');
            print('Document data:');

            // Print the space data in a more readable format
            spaceData.forEach((key, value) {
              print('  $key: $value');
            });

            // Ask for confirmation
            print('\nDo you want to delete this space? (Y/N)');
            final response = stdin.readLineSync()?.toLowerCase() ?? 'n';

            if (response == 'y') {
              try {
                await spaceDoc.reference.delete();
                totalSpacesDeleted++;
                print('  ✓ Successfully deleted space: $spaceId');
              } catch (e) {
                print('  ✗ Error deleting space: $e');
              }
            } else {
              print('  Skipped deletion of space: $spaceId');
            }

            print(''); // Empty line for readability
          }
        }
      }
    } catch (e) {
      print('Error processing spaces/$typePath/spaces: $e');
    }
  }

  // Final summary
  print('');
  print('Cleanup summary:');
  print('- Total spaces checked: $totalSpacesChecked');
  print('- Spaces with events: $totalSpacesWithEvents');
  print('- Spaces with minimal/no data: $totalEmptySpaces');
  print('- Spaces with minimal data + events: $totalEmptySpacesWithEvents');
  print('- Spaces deleted: $totalSpacesDeleted');

  if (totalEmptySpacesWithEvents == 0) {
    print('\nNo spaces with minimal data and events were found.');
    print(
        'You can now safely run cleanup_root_events.bat to delete the original events collection.');
  } else if (totalSpacesDeleted < totalEmptySpacesWithEvents) {
    print('\nNot all spaces with minimal data were deleted.');
    print(
        'Consider running this script again if you want to review the remaining spaces.');
  } else {
    print('\nAll spaces with minimal data and events have been deleted.');
    print(
        'You can now safely run cleanup_root_events.bat to delete the original events collection.');
  }
}
