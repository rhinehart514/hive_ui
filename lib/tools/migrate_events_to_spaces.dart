import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A command-line tool to migrate events from the flat collection structure
/// to be nested within their respective spaces in Firestore.
///
/// This tool creates a hierarchical structure:
/// spaces -> type of spaces -> space ID -> events -> event ID
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/migrate_events_to_spaces.dart [--interactive]
///
/// Where <device> can be:
///   - windows (for Windows)
///   - macos (for macOS)
///   - linux (for Linux)
///
/// Options:
///   --interactive    Run in interactive mode with confirmation prompts (default: automatic mode)

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Parse arguments - default to auto mode unless --interactive is specified
  final bool interactiveMode = args.contains('--interactive');
  // Define auto mode as opposite of interactive mode, but don't use it since we can just use !interactiveMode directly
  // Using final instead of commenting out to make it clear it's intentionally not used
  // final bool autoMode = !interactiveMode;

  print('==================================================');
  print('  HIVE UI - Event to Space Migration Tool');
  print('==================================================');
  print('');
  print('This tool will migrate events from the flat collection structure');
  print('to be nested within their respective spaces in Firestore.');
  print('');
  print('The new structure will be:');
  print('spaces -> type of spaces -> space ID -> events -> event ID');
  print('');
  print('Original events collection will be preserved.');
  print('');

  // Only ask for confirmation if in interactive mode
  if (interactiveMode) {
    print('WARNING: This is a one-way migration. While the original events');
    print('collection will be preserved, this operation changes how events');
    print('are stored and accessed in the database.');
    print('');
    print(
        'Type "yes" and press Enter to proceed with the migration, or anything else to cancel:');

    // Use this approach which works better with Flutter's console
    final input = stdin.readLineSync()?.toLowerCase() ?? '';
    if (input != 'yes') {
      print('Migration cancelled. Exiting...');
      exit(0);
    }
  } else {
    print(
        'Running in automatic mode. Migration will proceed without confirmation.');
  }

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting event migration process...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Initialize Space service settings
    await SpaceService.initSettings();

    // Call the migration method
    final stats = await migrateEventsToSpaces();

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);

    print('');
    print('Event migration completed in ${elapsedTime.inSeconds} seconds.');
    print('Total events migrated: ${stats.totalEventsMigrated}');
    print('Events without spaces: ${stats.eventsWithoutSpaces}');
    print('');
    print('Events migrated by space type:');
    print('  - Student Organizations: ${stats.studentOrgEvents}');
    print('  - University Organizations: ${stats.universityOrgEvents}');
    print('  - Campus Living: ${stats.campusLivingEvents}');
    print('  - Fraternity & Sorority: ${stats.fraternityAndSororityEvents}');
    print('  - Other: ${stats.otherEvents}');

    if (interactiveMode) {
      print('');
      print('Press any key to exit...');

      // Wait for user input before exiting
      await stdin.first;
    }
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete event migration:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');

    if (interactiveMode) {
      print('Press any key to exit...');

      // Wait for user input before exiting
      await stdin.first;
    }
    exit(1);
  }
}

/// Stats object to track migration progress
class MigrationStats {
  int totalEventsMigrated = 0;
  int eventsWithoutSpaces = 0;
  int studentOrgEvents = 0;
  int universityOrgEvents = 0;
  int campusLivingEvents = 0;
  int fraternityAndSororityEvents = 0;
  int otherEvents = 0;
}

/// Migrates events from flat collection to spaces
Future<MigrationStats> migrateEventsToSpaces() async {
  final firestore = FirebaseFirestore.instance;
  final stats = MigrationStats();

  // Get space collections
  print('Looking for spaces in type collections...');
  final Map<String, Map<String, dynamic>?> spacesMap = {};

  // List of collections to check for spaces
  final spaceCollections = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other_spaces'
  ];

  // Load spaces from all type collections
  for (final collection in spaceCollections) {
    print('  Checking collection: $collection');
    try {
      final collectionSnapshot = await firestore.collection(collection).get();
      print('  Found ${collectionSnapshot.docs.length} spaces in $collection');

      for (final spaceDoc in collectionSnapshot.docs) {
        try {
          final data = spaceDoc.data();
          spacesMap[spaceDoc.id] = data;
        } catch (e) {
          print(
              '  [WARNING] Could not get data for space ${spaceDoc.id} in $collection: $e');
          spacesMap[spaceDoc.id] = null;
        }
      }
    } catch (e) {
      print('  [WARNING] Error accessing collection $collection: $e');
    }
  }

  // If no spaces were found in the type collections, attempt to load from spaces collection
  if (spacesMap.isEmpty) {
    print(
        'No spaces found in type collections, checking main spaces collection...');
    try {
      final spacesSnapshot = await firestore.collection('spaces').get();
      print('Found ${spacesSnapshot.docs.length} spaces in main collection.');

      for (final spaceDoc in spacesSnapshot.docs) {
        try {
          final data = spaceDoc.data();
          spacesMap[spaceDoc.id] = data;
        } catch (e) {
          print('  [WARNING] Could not get data for space ${spaceDoc.id}: $e');
          spacesMap[spaceDoc.id] = null;
        }
      }
    } catch (e) {
      print('  [WARNING] Error accessing spaces collection: $e');
    }
  }

  print('Loaded a total of ${spacesMap.length} spaces from all collections.');
  print('');

  // Get all events from the events collection
  print('Fetching events from events collection...');
  final eventsSnapshot = await firestore.collection('events').get();
  final totalEvents = eventsSnapshot.docs.length;

  print('Found $totalEvents events to migrate.');
  print('');

  if (totalEvents == 0) {
    print('No events to migrate. Exiting...');
    return stats;
  }

  // Process events in batches to avoid memory issues
  const int batchSize = 50;
  int currentBatch = 0;

  for (int i = 0; i < totalEvents; i += batchSize) {
    currentBatch++;
    final endIndex =
        (i + batchSize < totalEvents) ? i + batchSize : totalEvents;
    final batchDocs = eventsSnapshot.docs.sublist(i, endIndex);

    print(
        'Processing batch $currentBatch/${(totalEvents / batchSize).ceil()} (events ${i + 1}-$endIndex of $totalEvents)');

    // Group events by space
    final Map<String, List<DocumentSnapshot>> eventsBySpace = {};
    final List<DocumentSnapshot> eventsWithoutSpace = [];

    for (final eventDoc in batchDocs) {
      try {
        // Extract event data
        final eventData = eventDoc.data();

        // Check if the event has an organizer name
        final String organizerName =
            eventData['organizerName'] as String? ?? '';

        if (organizerName.isEmpty) {
          // No organizer name, can't associate with a space
          eventsWithoutSpace.add(eventDoc);
          continue;
        }

        // Generate space ID from organizer name
        final String spaceId = generateSpaceId(organizerName);

        // Check if the space exists using our preloaded map instead of querying Firestore
        if (!spacesMap.containsKey(spaceId) || spacesMap[spaceId] == null) {
          // Space doesn't exist or has null data, can't associate
          print(
              '  [WARNING] Space not found or has null data for organizer: $organizerName (space ID: $spaceId)');
          eventsWithoutSpace.add(eventDoc);
          continue;
        }

        // Add to events by space map
        if (!eventsBySpace.containsKey(spaceId)) {
          eventsBySpace[spaceId] = [];
        }
        eventsBySpace[spaceId]!.add(eventDoc);
      } catch (e) {
        print('  [ERROR] Failed to process event ${eventDoc.id}: $e');
        eventsWithoutSpace.add(eventDoc);
      }
    }

    // Now migrate events to their respective spaces
    final List<Future<void>> migrationTasks = [];

    for (final entry in eventsBySpace.entries) {
      final spaceId = entry.key;
      final spaceEvents = entry.value;
      final spaceData = spacesMap[spaceId];

      if (spaceData != null) {
        migrationTasks
            .add(migrateEventsToSpace(spaceId, spaceEvents, spaceData, stats));
      } else {
        print('  [ERROR] Space data not found for ID: $spaceId');
        stats.eventsWithoutSpaces += spaceEvents.length;
      }
    }

    // Update stats for events without spaces
    stats.eventsWithoutSpaces += eventsWithoutSpace.length;

    // Wait for all migration tasks to complete
    await Future.wait(migrationTasks);

    print(
        '  Completed batch $currentBatch: ${eventsBySpace.length} spaces updated, ${eventsWithoutSpace.length} events without spaces');
  }

  return stats;
}

/// Migrates events to a specific space
Future<void> migrateEventsToSpace(
    String spaceId,
    List<DocumentSnapshot> eventDocs,
    Map<String, dynamic>
        spaceData, // Pass space data directly to avoid extra reads
    MigrationStats stats) async {
  final firestore = FirebaseFirestore.instance;

  try {
    // Get space type from the provided space data
    final String spaceTypeStr = spaceData['spaceType'] as String? ?? 'other';
    final SpaceType spaceType =
        SpaceTypeExtension.fromFirestoreValue(spaceTypeStr);

    // Log the space type for debugging
    print(
        '  Space $spaceId has type: $spaceTypeStr (enum: ${spaceType.displayName})');

    // Get type collection name
    final String spaceTypeCollection = getCollectionNameForSpaceType(spaceType);
    print('  Using collection: $spaceTypeCollection');

    // Create batch for efficient writing
    final batch = firestore.batch();
    int eventsInBatch = 0;

    // First, add the space document itself to the appropriate collection
    // Direct under the type collection (from screenshot)
    final targetSpaceRef =
        firestore.collection(spaceTypeCollection).doc(spaceId);

    // Set the space data in the new location
    batch.set(targetSpaceRef, spaceData);
    print('  Added space document to $spaceTypeCollection collection');

    for (final eventDoc in eventDocs) {
      // Get event data
      final eventData = eventDoc.data();

      // Target reference for the event in its new location
      // Events are in a subcollection under each space
      final targetEventRef = firestore
          .collection(spaceTypeCollection)
          .doc(spaceId)
          .collection('events')
          .doc(eventDoc.id);

      // Set the event data at the new location
      batch.set(targetEventRef, eventData);
      eventsInBatch++;

      // Update stats
      updateStatsForSpaceType(stats, spaceType);
    }

    // Commit the batch write
    await batch.commit();

    // Update total events migrated
    stats.totalEventsMigrated += eventsInBatch;

    print(
        '  Migrated $eventsInBatch events to space $spaceId (type: ${spaceType.displayName})');
  } catch (e) {
    print('  [ERROR] Failed to migrate events to space $spaceId: $e');
  }
}

/// Generate a space ID from organizer name
String generateSpaceId(String organizerName) {
  // Normalize the name (lowercase, remove special chars)
  final normalized = organizerName
      .toLowerCase()
      .replaceAll(RegExp(r'[^\w\s]'), '')
      .trim()
      .replaceAll(RegExp(r'\s+'), '_');

  return 'space_$normalized';
}

/// Get the collection name for a space type
String getCollectionNameForSpaceType(SpaceType spaceType) {
  switch (spaceType) {
    case SpaceType.studentOrg:
      return 'student_organizations';
    case SpaceType.universityOrg:
      return 'university_organizations';
    case SpaceType.campusLiving:
      return 'campus_living';
    case SpaceType.fraternityAndSorority:
      return 'fraternity_and_sorority';
    case SpaceType.hiveExclusive:
      return 'hive_exclusive';
    case SpaceType.other:
      return 'other_spaces';
  }
}

/// Update stats for space type
void updateStatsForSpaceType(MigrationStats stats, SpaceType spaceType) {
  switch (spaceType) {
    case SpaceType.studentOrg:
      stats.studentOrgEvents++;
      break;
    case SpaceType.universityOrg:
      stats.universityOrgEvents++;
      break;
    case SpaceType.campusLiving:
      stats.campusLivingEvents++;
      break;
    case SpaceType.fraternityAndSorority:
      stats.fraternityAndSororityEvents++;
      break;
    case SpaceType.hiveExclusive:
      // Count HIVE exclusive events in a separate field if available
      // For now, just use other events as a fallback
      stats.otherEvents++;
      break;
    case SpaceType.other:
      stats.otherEvents++;
      break;
  }
}
