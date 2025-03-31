import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/spaces/utils/space_duplicate_merger.dart';
import 'package:hive_ui/firebase_options.dart';

/// Command-line entry point for running the space merger process
/// This script can be run directly without UI:
/// flutter run -t lib/tools/run_space_merger.dart
void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  print('=== HIVE UI Space Merger Tool ===');
  print('Initializing Firebase...');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  print('Firebase initialized.');
  print('Running space merger process...');

  try {
    // Run the merger process
    await SpaceDuplicateMerger.runFullMergeProcess();

    print('Space merger completed successfully!');
  } catch (e) {
    print('Error running space merger: $e');
  }

  // Exit the application
  print('Process complete. Exiting...');
}
