import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/services/admin_tools.dart';

/// A utility script to verify event-space assignments and fix any issues
/// This ensures all events are properly assigned to spaces based on organizer name
void main() async {
  // Initialize Flutter and Firebase
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Event-Space Assignment Verifier & Fixer');
  print('==================================================');
  print('');
  print('This utility will:');
  print('1. Verify that all events are assigned to appropriate spaces');
  print('2. Fix any events that are not assigned to spaces');
  print('3. Report on the results and any remaining issues');
  print('');

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('\nStarting verification and fix process...');

    // Create admin tools instance
    final adminTools = AdminTools();

    // Run the verification and fix process
    final results = await adminTools.verifyAndFixEventSpaceAssignments();

    print('\nProcess completed successfully.');

    // Determine if there are any remaining unassigned events with null safety
    final finalState = results['finalState'] as Map<String, dynamic>?;
    final unassignedEvents = finalState != null &&
            finalState.containsKey('unassignedEvents') &&
            finalState['unassignedEvents'] != null
        ? finalState['unassignedEvents'] as List
        : <dynamic>[];
    final int unassignedCount = unassignedEvents.length;

    if (unassignedCount > 0) {
      print(
          '\nThere are still $unassignedCount events not assigned to spaces.');
      print('You may need to manually add organizer names to some events.');
    } else {
      print('\nAll events are now properly assigned to spaces!');
    }

    print('\nExiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(0);
  } catch (e, stackTrace) {
    print('\nERROR: An unexpected error occurred:');
    print(e);
    print('\nStack trace:');
    print(stackTrace);

    print('\nExiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(1);
  }
}
