import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/admin_tools.dart';

/// Command-line utility to sync clubs from local cache to Firestore
Future<void> main() async {
  print('HIVE UI - Club Sync Utility');
  print('=========================');
  print('This utility manages club data in Firestore.');
  print('Initializing...');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized.');

  // Show menu
  print('\nPlease select an option:');
  print('1. Sync clubs from local cache to Firestore');
  print('2. Load clubs from Firestore to local cache');
  print('3. Generate clubs from events');
  print(
      '4. Categorize clubs into branches (university_departments, greek_life, etc.)');
  print('5. Exit');

  // Get user choice
  stdout.write('\nEnter your choice (1-5): ');
  final choice = stdin.readLineSync()?.trim();

  try {
    switch (choice) {
      case '1':
        await _syncClubsToFirestore();
        break;
      case '2':
        await _loadClubsFromFirestore();
        break;
      case '3':
        await _generateClubsFromEvents();
        break;
      case '4':
        await _categorizeClubs();
        break;
      case '5':
        print('Exiting...');
        exit(0);
        break;
      default:
        print('Invalid choice. Exiting...');
        exit(1);
    }
  } catch (e) {
    print('❌ Error: $e');
    exit(1);
  }

  print('Process completed.');
  exit(0);
}

/// Sync clubs from local cache to Firestore
Future<void> _syncClubsToFirestore() async {
  print('\nSYNC CLUBS TO FIRESTORE');
  print('=========================');

  // First try to load clubs from Firestore (in case they're already there)
  final loadCount = await AdminTools.loadClubsFromFirestore();
  print('Loaded $loadCount clubs from Firestore');

  if (loadCount > 0) {
    print('Clubs already exist in Firestore. Do you want to sync again? (y/n)');
    final input = stdin.readLineSync()?.toLowerCase();

    if (input != 'y') {
      print(
          'Sync cancelled. Existing clubs from Firestore kept in local cache.');
      return;
    }
  }

  // Sync clubs to Firestore
  final success = await AdminTools.syncClubsToFirestore();

  if (success) {
    print('✅ Clubs successfully synced to Firestore!');
  } else {
    print('❌ Failed to sync clubs to Firestore.');
  }
}

/// Load clubs from Firestore to local cache
Future<void> _loadClubsFromFirestore() async {
  print('\nLOAD CLUBS FROM FIRESTORE');
  print('=========================');

  final count = await AdminTools.loadClubsFromFirestore();

  if (count > 0) {
    print('✅ Successfully loaded $count clubs from Firestore to local cache');
  } else {
    print('❌ No clubs found in Firestore or error occurred during loading');
  }
}

/// Generate clubs from events
Future<void> _generateClubsFromEvents() async {
  print('\nGENERATE CLUBS FROM EVENTS');
  print('=========================');

  print('This will generate clubs from events in the event cache.');
  print('Do you want to proceed? (y/n)');

  final input = stdin.readLineSync()?.toLowerCase();

  if (input != 'y') {
    print('Operation cancelled.');
    return;
  }

  final count = await AdminTools.generateClubsFromExistingEvents();

  if (count > 0) {
    print('✅ Generated and synced $count clubs from events');
  } else {
    print('❌ Failed to generate clubs from events');
  }
}

/// Categorize clubs into branches based on RSS categories
Future<void> _categorizeClubs() async {
  print('\nCATEGORIZE CLUBS INTO BRANCHES');
  print('=========================');

  print('This will categorize clubs into the following branches:');
  for (final branch in AdminTools.branchTypes) {
    print('- $branch');
  }

  print('\nClubs will be categorized based on:');
  print('- Club name');
  print('- RSS feed category');
  print('- Club description');

  print('\nDo you want to proceed? (y/n)');
  final input = stdin.readLineSync()?.toLowerCase();

  if (input != 'y') {
    print('Operation cancelled.');
    return;
  }

  print('Categorizing clubs...');
  await AdminTools.categorizeClubsInFirestore();
  print('✅ Club categorization completed');
}
