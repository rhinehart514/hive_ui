import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A command-line tool to sync all RSS events to Firestore in a single batch operation
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/sync_all_events.dart
///
/// Where <device> can be:
///   - windows (for Windows)
///   - macos (for macOS)
///   - linux (for Linux)
///
/// Example: flutter run -d windows lib/tools/sync_all_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Sync All RSS Events to Firestore Tool');
  print('==================================================');
  print('');
  print(
      'This tool will sync all events from the RSS feed to Firestore in one batch operation.');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting batch sync operation...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Call the batch sync method
    await RssService.batchSyncAllEventsToFirestore();

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);

    print('');
    print(
        'Batch sync operation completed in ${elapsedTime.inSeconds} seconds.');
    print('');

    // Update the scheduler timestamp to prevent immediate re-sync
    print('Updating scheduler timestamp...');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        'last_rss_update_timestamp', DateTime.now().millisecondsSinceEpoch);
    print(
        'Scheduler timestamp updated. Next automatic sync will be in 7 days.');

    // Verify and provide statistics on the synced events
    print('Verifying events in Firestore...');
    await verifyEventsInFirestore();

    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete batch sync operation:');
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

/// Verifies the events in Firestore and provides statistics
Future<void> verifyEventsInFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Get the events collection
    final eventsCollection = firestore.collection('events');

    // Get the total count of events
    final eventsSnapshot = await eventsCollection.get();
    final totalEvents = eventsSnapshot.docs.length;

    print('Total events in Firestore: $totalEvents');

    // Get the last sync metadata
    final metadataSnapshot =
        await firestore.collection('metadata').doc('rss_sync').get();
    if (metadataSnapshot.exists) {
      final metadata = metadataSnapshot.data();
      print('Last sync details:');
      print('  Status: ${metadata?['status'] ?? 'unknown'}');
      print('  Events synced: ${metadata?['event_count'] ?? 'unknown'}');

      final startedAt = metadata?['started_at'];
      if (startedAt != null) {
        final startTimestamp = (startedAt as Timestamp).toDate();
        print('  Started at: ${startTimestamp.toLocal()}');
      }

      final completedAt = metadata?['completed_at'];
      if (completedAt != null) {
        final completedTimestamp = (completedAt as Timestamp).toDate();
        print('  Completed at: ${completedTimestamp.toLocal()}');
      }
    } else {
      print('No sync metadata found');
    }

    // Get a sample of events to verify structure
    if (totalEvents > 0) {
      print('');
      print('Checking event structure with a sample:');

      final sampleEvents = await eventsCollection.limit(1).get();
      final sampleEvent = sampleEvents.docs.first.data();

      // Extract and display key fields
      print('  Event ID: ${sampleEvents.docs.first.id}');
      print('  Title: ${sampleEvent['title'] ?? 'missing'}');
      print('  Start Date: ${sampleEvent['startDate'] ?? 'missing'}');
      print('  Organizer: ${sampleEvent['organizerName'] ?? 'missing'}');

      // Check for required fields
      final missingFields = <String>[];
      for (var field in ['title', 'description', 'startDate', 'endDate', 'location']) {
        if (!sampleEvent.containsKey(field) || sampleEvent[field] == null) {
          missingFields.add(field);
        }
      }

      if (missingFields.isNotEmpty) {
        print('');
        print(
            'WARNING: Sample event is missing required fields: ${missingFields.join(', ')}');
      } else {
        print('');
        print(
            'All required fields present in sample event. Data structure looks correct.');
      }
    }

    // Check for events by date ranges
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekLater = todayStart.add(const Duration(days: 7));
    final monthLater = todayStart.add(const Duration(days: 30));

    // Count upcoming events
    final upcomingEventsQuery = eventsCollection.where('startDate',
        isGreaterThanOrEqualTo: todayStart.toIso8601String());

    final upcomingEvents = await upcomingEventsQuery.count().get();

    // Count events in the next week
    final weekEventsQuery = eventsCollection
        .where('startDate',
            isGreaterThanOrEqualTo: todayStart.toIso8601String())
        .where('startDate', isLessThanOrEqualTo: weekLater.toIso8601String());

    final weekEvents = await weekEventsQuery.count().get();

    // Count events in the next month
    final monthEventsQuery = eventsCollection
        .where('startDate',
            isGreaterThanOrEqualTo: todayStart.toIso8601String())
        .where('startDate', isLessThanOrEqualTo: monthLater.toIso8601String());

    final monthEvents = await monthEventsQuery.count().get();

    print('');
    print('Event date ranges:');
    print('  Upcoming events: ${upcomingEvents.count}');
    print('  Events in the next 7 days: ${weekEvents.count}');
    print('  Events in the next 30 days: ${monthEvents.count}');

    if (upcomingEvents.count == 0) {
      print('');
      print(
          'WARNING: No upcoming events found in Firestore. This may indicate a problem with the sync process.');
    } else {
      print('');
      print(
          'Verification complete. Events have been successfully synced to Firestore.');
      print(
          'The app will now use Firestore as the primary data source, with weekly background RSS updates.');
    }
  } catch (e) {
    print('');
    print('Error verifying events: $e');
  }
}
