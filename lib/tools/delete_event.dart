import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/space_event_manager.dart';
import 'dart:io';

/// A utility to delete events from Firestore
///
/// Events are stored at: spaces/[spacetype]/spaces/[spaceID]/events/[eventID]
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Delete Events Tool');
  print('==================================================');
  print('');
  print('This utility will delete events from spaces based on criteria');
  print('from the path: spaces/[spacetype]/spaces/[spaceID]/events/[eventID]');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    // Run the CLI app
    await runDeleteEventsCLI();
  } catch (e) {
    print('Error: $e');
  }
}

/// Run the delete events CLI
Future<void> runDeleteEventsCLI() async {
  print('\nSelect an operation:');
  print('1. Delete a specific event');
  print('2. Delete all events from a specific space');
  print('3. Delete events by date range');
  print('4. Exit');

  print('\nEnter your choice (1-4): ');
  final input = stdin.readLineSync();

  switch (input) {
    case '1':
      await deleteSpecificEvent();
      break;
    case '2':
      await deleteAllEventsFromSpace();
      break;
    case '3':
      await deleteEventsByDateRange();
      break;
    case '4':
      print('Exiting...');
      return;
    default:
      print('Invalid choice. Please try again.');
      await runDeleteEventsCLI();
  }
}

/// Delete a specific event
Future<void> deleteSpecificEvent() async {
  print('\n--- Delete Specific Event ---');

  print(
      'Enter space type (student_organizations, university_organizations, etc.): ');
  final spaceType = stdin.readLineSync();

  print('Enter space ID: ');
  final spaceId = stdin.readLineSync();

  print('Enter event ID: ');
  final eventId = stdin.readLineSync();

  if (spaceType == null ||
      spaceId == null ||
      eventId == null ||
      spaceType.isEmpty ||
      spaceId.isEmpty ||
      eventId.isEmpty) {
    print('Error: All fields are required.');
    return deleteSpecificEvent();
  }

  print('\nDeleting event $eventId from space $spaceId (type: $spaceType)...');

  final success = await SpaceEventManager.deleteEvent(
    eventId: eventId,
    spaceId: spaceId,
    spaceType: spaceType,
  );

  if (success) {
    print('Successfully deleted event.');
  } else {
    print('Failed to delete event.');
  }

  // Return to menu
  print('\nPress Enter to continue...');
  stdin.readLineSync();
  await runDeleteEventsCLI();
}

/// Delete all events from a specific space
Future<void> deleteAllEventsFromSpace() async {
  print('\n--- Delete All Events From Space ---');

  print(
      'Enter space type (student_organizations, university_organizations, etc.): ');
  final spaceType = stdin.readLineSync();

  print('Enter space ID: ');
  final spaceId = stdin.readLineSync();

  if (spaceType == null ||
      spaceId == null ||
      spaceType.isEmpty ||
      spaceId.isEmpty) {
    print('Error: All fields are required.');
    return deleteAllEventsFromSpace();
  }

  print(
      '\nWARNING: This will delete ALL events from space $spaceId (type: $spaceType).');
  print('Are you sure? (y/n): ');
  final confirm = stdin.readLineSync()?.toLowerCase();

  if (confirm != 'y') {
    print('Operation cancelled.');
    await runDeleteEventsCLI();
    return;
  }

  print('\nDeleting all events from space $spaceId (type: $spaceType)...');

  final firestore = FirebaseFirestore.instance;
  final eventsCollection = firestore
      .collection('spaces')
      .doc(spaceType)
      .collection('spaces')
      .doc(spaceId)
      .collection('events');

  // Get all events in this space
  final eventsSnapshot = await eventsCollection.get();
  final totalEvents = eventsSnapshot.docs.length;

  print('Found $totalEvents events to delete.');

  if (totalEvents == 0) {
    print('No events to delete.');
    // Return to menu
    print('\nPress Enter to continue...');
    stdin.readLineSync();
    await runDeleteEventsCLI();
    return;
  }

  // Delete events in batches
  int deleted = 0;
  final batch = firestore.batch();
  int batchCount = 0;

  for (final eventDoc in eventsSnapshot.docs) {
    batch.delete(eventDoc.reference);
    batchCount++;
    deleted++;

    // Commit batch every 500 operations (Firestore limit)
    if (batchCount >= 500) {
      await batch.commit();
      print(
          'Deleted batch of $batchCount events (total: $deleted/$totalEvents)');
      batchCount = 0;
    }
  }

  // Commit any remaining deletes
  if (batchCount > 0) {
    await batch.commit();
    print('Deleted final batch of $batchCount events');
  }

  print('Successfully deleted $deleted events from space $spaceId.');

  // Return to menu
  print('\nPress Enter to continue...');
  stdin.readLineSync();
  await runDeleteEventsCLI();
}

/// Delete events by date range
Future<void> deleteEventsByDateRange() async {
  print('\n--- Delete Events By Date Range ---');

  print(
      'Enter space type (student_organizations, university_organizations, etc.): ');
  final spaceType = stdin.readLineSync();

  print('Enter space ID: ');
  final spaceId = stdin.readLineSync();

  if (spaceType == null ||
      spaceId == null ||
      spaceType.isEmpty ||
      spaceId.isEmpty) {
    print('Error: Space type and ID are required.');
    return deleteEventsByDateRange();
  }

  print('Enter start date (YYYY-MM-DD), or leave blank for no start limit: ');
  final startDateStr = stdin.readLineSync();

  print('Enter end date (YYYY-MM-DD), or leave blank for no end limit: ');
  final endDateStr = stdin.readLineSync();

  DateTime? startDate;
  DateTime? endDate;

  if (startDateStr != null && startDateStr.isNotEmpty) {
    try {
      startDate = DateTime.parse(startDateStr);
    } catch (e) {
      print('Error parsing start date. Please use format YYYY-MM-DD.');
      return deleteEventsByDateRange();
    }
  }

  if (endDateStr != null && endDateStr.isNotEmpty) {
    try {
      endDate = DateTime.parse(endDateStr);
      // Set to end of day
      endDate = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    } catch (e) {
      print('Error parsing end date. Please use format YYYY-MM-DD.');
      return deleteEventsByDateRange();
    }
  }

  if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
    print('Error: Start date cannot be after end date.');
    return deleteEventsByDateRange();
  }

  print(
      '\nSearching for events between ${startDate?.toString() ?? 'any'} and ${endDate?.toString() ?? 'any'}...');

  final firestore = FirebaseFirestore.instance;
  Query eventsQuery = firestore
      .collection('spaces')
      .doc(spaceType)
      .collection('spaces')
      .doc(spaceId)
      .collection('events');

  // Apply date filters if provided
  if (startDate != null) {
    eventsQuery = eventsQuery.where('startDate',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
  }

  if (endDate != null) {
    eventsQuery = eventsQuery.where('startDate',
        isLessThanOrEqualTo: Timestamp.fromDate(endDate));
  }

  // Get events matching criteria
  final eventsSnapshot = await eventsQuery.get();
  final totalEvents = eventsSnapshot.docs.length;

  print('Found $totalEvents events matching the criteria.');

  if (totalEvents == 0) {
    print('No events to delete.');
    // Return to menu
    print('\nPress Enter to continue...');
    stdin.readLineSync();
    await runDeleteEventsCLI();
    return;
  }

  print('\nWARNING: This will delete $totalEvents events.');
  print('Are you sure? (y/n): ');
  final confirm = stdin.readLineSync()?.toLowerCase();

  if (confirm != 'y') {
    print('Operation cancelled.');
    await runDeleteEventsCLI();
    return;
  }

  // Delete events in batches
  int deleted = 0;
  final batch = firestore.batch();
  int batchCount = 0;

  for (final eventDoc in eventsSnapshot.docs) {
    batch.delete(eventDoc.reference);
    batchCount++;
    deleted++;

    // Commit batch every 500 operations (Firestore limit)
    if (batchCount >= 500) {
      await batch.commit();
      print(
          'Deleted batch of $batchCount events (total: $deleted/$totalEvents)');
      batchCount = 0;
    }
  }

  // Commit any remaining deletes
  if (batchCount > 0) {
    await batch.commit();
    print('Deleted final batch of $batchCount events');
  }

  print('Successfully deleted $deleted events from space $spaceId.');

  // Return to menu
  print('\nPress Enter to continue...');
  stdin.readLineSync();
  await runDeleteEventsCLI();
}
