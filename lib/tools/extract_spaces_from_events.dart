import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/space_event_service.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A command-line tool to extract spaces from events in Firestore
///
/// This tool is designed to be run directly with Flutter:
/// flutter run -d <device> lib/tools/extract_spaces_from_events.dart
///
/// Where <device> can be:
///   - windows (for Windows)
///   - macos (for macOS)
///   - linux (for Linux)
///
/// Example: flutter run -d windows lib/tools/extract_spaces_from_events.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Extract Spaces from Events Tool');
  print('==================================================');
  print('');
  print(
      'This tool will extract spaces from all events in Firestore, categorize them into:');
  print('  - Student Organizations');
  print('  - University Organizations');
  print('  - Campus Living');
  print('  - Fraternity & Sorority');
  print('  - Other');
  print('');
  print('Each space will be linked to its respective events.');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting space extraction process...');
    print('');

    // Record start time for performance measurement
    final startTime = DateTime.now();

    // Initialize Space service settings
    await SpaceService.initSettings();

    // Call the space extraction method
    final processedSpaces = await SpaceEventService.processAllExistingEvents();

    // Calculate elapsed time
    final elapsedTime = DateTime.now().difference(startTime);

    print('');
    print('Space extraction completed in ${elapsedTime.inSeconds} seconds.');
    print('Total spaces created: $processedSpaces');

    // Verify and provide statistics on the extracted spaces
    print('');
    print('Verifying spaces in Firestore...');
    await verifySpacesInFirestore();

    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete space extraction:');
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

/// Verifies the spaces in Firestore and provides statistics
Future<void> verifySpacesInFirestore() async {
  try {
    final firestore = FirebaseFirestore.instance;

    // Get the spaces collection
    final spacesCollection = firestore.collection('spaces');

    // Get the total count of spaces
    final spacesSnapshot = await spacesCollection.get();
    final totalSpaces = spacesSnapshot.docs.length;

    print('Total spaces in Firestore: $totalSpaces');

    if (totalSpaces > 0) {
      // Count spaces by type
      print('');
      print('Spaces by type:');

      final studentOrgsQuery =
          spacesCollection.where('spaceType', isEqualTo: 'studentOrg');
      final studentOrgsCount = await studentOrgsQuery.count().get();
      print('  Student Organizations: ${studentOrgsCount.count}');

      final universityOrgsQuery =
          spacesCollection.where('spaceType', isEqualTo: 'universityOrg');
      final universityOrgsCount = await universityOrgsQuery.count().get();
      print('  University Organizations: ${universityOrgsCount.count}');

      final campusLivingQuery =
          spacesCollection.where('spaceType', isEqualTo: 'campusLiving');
      final campusLivingCount = await campusLivingQuery.count().get();
      print('  Campus Living: ${campusLivingCount.count}');

      final fraternityAndSororityQuery = spacesCollection.where('spaceType',
          isEqualTo: 'fraternityAndSorority');
      final fraternityAndSororityCount =
          await fraternityAndSororityQuery.count().get();
      print('  Fraternity & Sorority: ${fraternityAndSororityCount.count}');

      final otherQuery =
          spacesCollection.where('spaceType', isEqualTo: 'other');
      final otherCount = await otherQuery.count().get();
      print('  Other: ${otherCount.count}');

      // Get a sample space to inspect
      print('');
      print('Checking space structure with a sample:');

      final sampleSpaces = await spacesCollection.limit(1).get();
      final sampleSpace =
          sampleSpaces.docs.first.data();

      // Extract and display key fields
      print('  Space ID: ${sampleSpaces.docs.first.id}');
      print('  Name: ${sampleSpace['name'] ?? 'missing'}');
      print('  Description: ${sampleSpace['description'] ?? 'missing'}');
      print('  Type: ${sampleSpace['spaceType'] ?? 'missing'}');

      // Check for event links
      final eventIds = sampleSpace['eventIds'] as List<dynamic>?;
      if (eventIds != null && eventIds.isNotEmpty) {
        print('  Linked Events: ${eventIds.length}');

        // Check a linked event
        final eventId = eventIds.first.toString();
        final eventDoc =
            await firestore.collection('events').doc(eventId).get();
        if (eventDoc.exists) {
          final eventData = eventDoc.data() as Map<String, dynamic>;
          print('');
          print('Sample linked event:');
          print('  Event ID: $eventId');
          print('  Title: ${eventData['title'] ?? 'missing'}');
          print('  Organizer: ${eventData['organizerName'] ?? 'missing'}');
        } else {
          print('');
          print('WARNING: Referenced event $eventId does not exist');
        }
      } else {
        print('  Linked Events: None');
        print('');
        print('WARNING: Sample space has no linked events.');
      }

      // Check for metrics
      if (sampleSpace.containsKey('metrics')) {
        final metrics = sampleSpace['metrics'] as Map<String, dynamic>;
        print('');
        print('Space metrics:');
        print('  Weekly Events: ${metrics['weeklyEvents'] ?? 'missing'}');
        print('  Engagement Score: ${metrics['engagementScore'] ?? 'missing'}');
        print('  Has New Content: ${metrics['hasNewContent'] ?? 'missing'}');
        print('  Is Trending: ${metrics['isTrending'] ?? 'missing'}');
      } else {
        print('');
        print('WARNING: Sample space is missing metrics.');
      }

      print('');
      print(
          'Verification complete. Spaces have been successfully extracted from events in Firestore.');
    } else {
      print('');
      print(
          'WARNING: No spaces found in Firestore. Space extraction may have failed.');
    }
  } catch (e) {
    print('');
    print('Error verifying spaces: $e');
  }
}
