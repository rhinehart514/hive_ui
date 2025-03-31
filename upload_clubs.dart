import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/admin_tools.dart';
import 'package:flutter/material.dart';

/// Simple utility to sync clubs directly to Firestore
Future<void> main() async {
  // Initialize Flutter
  WidgetsFlutterBinding.ensureInitialized();

  print('HIVE UI - Direct Club Sync');
  print('=========================');
  print('Initializing Firebase...');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized. Starting sync process...');

  try {
    // Step 1: First try to generate clubs from events (if needed)
    final clubsGenerated = await AdminTools.generateClubsFromExistingEvents();
    print('Generated $clubsGenerated clubs from events');

    // Step 2: Sync all clubs to Firestore
    final syncSuccess = await AdminTools.syncClubsToFirestore();

    if (syncSuccess) {
      print('✅ Clubs successfully synced to Firestore!');

      // Step 3: Categorize clubs into branches
      print('Categorizing clubs into branches...');
      await AdminTools.categorizeClubsInFirestore();
      print('✅ Club categorization completed');
    } else {
      print('❌ Failed to sync clubs to Firestore.');
    }
  } catch (e) {
    print('❌ Error: $e');
  }

  print('Process completed.');
}
