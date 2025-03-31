import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/rss_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A command-line tool to migrate lost events to appropriate spaces
/// This tool will create spaces for events if they don't exist
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/migrate_lost_events.dart
///
/// Where <device> can be:
///   - windows (for Windows)
///   - macos (for macOS)
///   - linux (for Linux)
///
/// Example: flutter run -d windows lib/tools/migrate_lost_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('==================================================');
  debugPrint('  HIVE UI - Migrate Lost Events to Spaces Tool');
  debugPrint('==================================================');
  debugPrint('');
  debugPrint(
      'This tool will migrate events from the lost_events collection to appropriate spaces.');
  debugPrint('Spaces will be created for events if they don\'t exist already.');
  debugPrint('');

  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized successfully.');

    debugPrint('');
    debugPrint('Starting migration operation...');
    debugPrint('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Run the migration
    final result = await RssService.migrateLostEventsToSpaces();

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);

    debugPrint('');
    debugPrint(
        'Migration operation completed in ${elapsedTime.inSeconds} seconds.');
    debugPrint('');

    // Print results
    debugPrint('Migration Results:');
    debugPrint('  Total events processed: ${result['total']}');
    debugPrint('  Successfully migrated: ${result['migrated']}');
    debugPrint('  Failed to migrate: ${result['failed']}');
    debugPrint('  New spaces created: ${result['spaces_created']}');

    // Wait for console output to complete
    await Future.delayed(const Duration(seconds: 1));

    // Verify the count of remaining lost events
    debugPrint('');
    debugPrint('Verifying remaining lost events...');
    final remainingLostEvents = await FirebaseFirestore.instance
        .collection('lost_events')
        .count()
        .get();

    debugPrint(
        'Remaining events in lost_events collection: ${remainingLostEvents.count}');

    if ((remainingLostEvents.count ?? 0) > 0) {
      debugPrint('');
      debugPrint('NOTE: Some events remain in the lost_events collection.');
      debugPrint(
          'These may be events with no organizer name or that failed to migrate.');
      debugPrint('You can run this tool again to attempt to migrate them.');
    } else {
      debugPrint('');
      debugPrint(
          'SUCCESS: All lost events have been successfully migrated to spaces!');
    }

    debugPrint('');
    debugPrint('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    debugPrint('');
    debugPrint('ERROR: Failed to complete migration operation:');
    debugPrint('$e');
    debugPrint('');
    debugPrint('Stack trace:');
    debugPrint('$stackTrace');
    debugPrint('');
    debugPrint('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(1);
  }
}
