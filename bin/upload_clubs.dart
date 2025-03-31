// A standalone Dart script to upload clubs to Firestore
// This avoids Flutter dependencies to prevent compatibility issues

import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/admin_tools.dart';

void main() async {
  print('Starting clubs sync process...');

  // Initialize Firebase with defaults for Dart script
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized successfully');

  try {
    print('Generating clubs from events...');
    await AdminTools.generateClubsFromExistingEvents();
    print('✅ Clubs generated from events successfully');

    print('Syncing clubs to Firestore...');
    await AdminTools.syncClubsToFirestore();
    print('✅ Clubs synced to Firestore successfully');

    print('Categorizing clubs into branches...');
    await AdminTools.categorizeClubsInFirestore();
    print('✅ Clubs categorized into branches successfully');

    print('All operations completed successfully!');
  } catch (e) {
    print('❌ Error during club sync process: $e');
  } finally {
    print('Club sync process finished');
    exit(0); // Force exit to prevent hanging
  }
}
