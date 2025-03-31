import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to migrate events from the root events collection to their appropriate spaces based on the event organizer
///
/// This script will:
/// 1. Find all events in the root events collection
/// 2. For each event, determine the appropriate space based on the organizerName
/// 3. Find that space in the type-specific collections
/// 4. Only move events to spaces that have actual data
/// 5. Move the event to the appropriate space
///
/// Run with: flutter run -d windows lib/tools/migrate_root_events_to_spaces.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Migrate Root Events to Spaces');
  print('==================================================');
  print('');
  print('This utility will migrate events from the root events collection');
  print('to their appropriate spaces based on the event organizer.');
  print('Only events whose spaces have actual data will be migrated.');
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

    await migrateRootEventsToSpaces();

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

/// Helper function to find a space document based on organizer name
Future<DocumentReference?> findSpaceForOrganizer(
    FirebaseFirestore firestore, String organizerName) async {
  // First, create a standardized space ID from organizer name
  String possibleSpaceId = 'space_${organizerName
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '')}';

  // Check in all type collections
  for (final typePath in getTypePaths()) {
    // Check if space exists with this ID
    final spaceRef = firestore
        .collection('spaces')
        .doc(typePath)
        .collection('spaces')
        .doc(possibleSpaceId);

    final spaceDoc = await spaceRef.get();

    // Only return spaces that have actual data
    if (spaceDoc.exists &&
        spaceDoc.data() != null &&
        (spaceDoc.data() as Map).isNotEmpty) {
      print('Found space for organizer "$organizerName" at ${spaceRef.path}');
      return spaceRef;
    }

    // Also try a direct match on the name field
    // This is more expensive but more accurate for finding the right space
    try {
      final nameQuerySnapshot = await firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .where('name', isEqualTo: organizerName)
          .limit(1)
          .get();

      if (nameQuerySnapshot.docs.isNotEmpty) {
        final foundSpaceRef = nameQuerySnapshot.docs.first.reference;
        print(
            'Found space for organizer "$organizerName" by name match at ${foundSpaceRef.path}');
        return foundSpaceRef;
      }
    } catch (e) {
      print('Error searching by name for "$organizerName": $e');
    }
  }

  print('No space found for organizer: "$organizerName"');
  return null;
}

/// Migrate events from the root events collection to their appropriate spaces
Future<void> migrateRootEventsToSpaces() async {
  final firestore = FirebaseFirestore.instance;

  // Get all events from the root collection
  print('Fetching events from root collection...');
  final eventsQuery = await firestore.collection('events').get();
  print('Found ${eventsQuery.docs.length} events in root collection');

  int totalProcessed = 0;
  int totalMigrated = 0;
  int totalSkipped = 0;
  int totalNoSpaceFound = 0;
  int totalAlreadyExists = 0;

  // Cache space references to avoid duplicate lookups
  Map<String, DocumentReference?> spaceCache = {};

  // Process each event
  for (final eventDoc in eventsQuery.docs) {
    try {
      totalProcessed++;
      final eventId = eventDoc.id;

      // Safely get data - handle null case that was causing the crash
      final eventData = eventDoc.data();

      // Skip events without organizer info
      if (!eventData.containsKey('organizerName') ||
          eventData['organizerName'] == null) {
        print('Event $eventId has no organizerName - skipping');
        totalSkipped++;
        continue;
      }

      final organizerName = eventData['organizerName'] as String;

      // Check if we've already found this organizer's space
      DocumentReference? spaceRef;
      if (spaceCache.containsKey(organizerName)) {
        spaceRef = spaceCache[organizerName];
      } else {
        // Find the space for this organizer
        spaceRef = await findSpaceForOrganizer(firestore, organizerName);
        spaceCache[organizerName] = spaceRef;
      }

      // If no space was found, skip this event
      if (spaceRef == null) {
        print(
            'No valid space found for event: $eventId (organizer: $organizerName) - skipping');
        totalNoSpaceFound++;
        continue;
      }

      try {
        // Check if the event already exists in the destination to prevent duplicates
        final destinationEventRef = spaceRef.collection('events').doc(eventId);
        final existingEvent = await destinationEventRef.get();

        if (existingEvent.exists) {
          print(
              'Event $eventId already exists in ${spaceRef.path}/events - skipping');
          totalAlreadyExists++;
          continue;
        }

        // Create event in the space's events collection
        await destinationEventRef.set(eventData);
        print('Migrated event $eventId to ${spaceRef.path}/events');
        totalMigrated++;
      } catch (e) {
        print('Error migrating event $eventId: $e');
        totalSkipped++;
      }
    } catch (e) {
      print('Error processing event: $e');
      totalSkipped++;
    }
  }

  // Final summary
  print('');
  print('Migration summary:');
  print('- Total events processed: $totalProcessed');
  print('- Events successfully migrated: $totalMigrated');
  print('- Events already existing in destination: $totalAlreadyExists');
  print('- Events with no space found: $totalNoSpaceFound');
  print('- Events skipped due to errors: $totalSkipped');

  if (totalMigrated > 0 || totalAlreadyExists > 0) {
    print('');
    print('IMPORTANT: Events have been copied to spaces.');
    print('After verifying the migration, you can:');
    print(
        '1. Run cleanup_spaces_with_events_only.bat to remove spaces with no data but events');
    print(
        '2. Run cleanup_root_events.bat to delete the original events collection');
  }
}
