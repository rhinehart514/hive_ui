import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up empty space documents in type subcollections.
///
/// This script will:
/// 1. Check each type subcollection for documents that have no fields (empty documents)
/// 2. Remove these empty documents (likely duplicates)
///
/// Run with: flutter run -d windows lib/tools/cleanup_empty_spaces.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Clean Up Empty Space Documents');
  print('==================================================');
  print('');
  print('This utility will remove empty space documents (with no fields)');
  print('from the type subcollections - these are likely duplicates.');
  print('');

  print('Starting in 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting cleanup of empty space documents...');
    print('');

    await cleanupEmptySpaceDocuments();

    print('');
    print('Operation completed successfully.');
    print('');
    print('Exiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete operation:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Exiting in 3 seconds...');
    await Future.delayed(const Duration(seconds: 3));
    exit(1);
  }
}

/// Cleanup empty space documents in type subcollections
Future<void> cleanupEmptySpaceDocuments() async {
  final firestore = FirebaseFirestore.instance;

  // Type paths
  final List<String> typePaths = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other',
  ];

  int totalEmptyDocs = 0;
  int totalRemoved = 0;

  // Check each type collection
  for (final typePath in typePaths) {
    print('Checking spaces/$typePath/spaces collection...');

    try {
      // Get all documents in the type subcollection
      final QuerySnapshot spaceQuery = await firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .get();

      print(
          'Found ${spaceQuery.docs.length} documents in spaces/$typePath/spaces');

      // Check for empty documents
      int emptyDocCount = 0;
      var batch = firestore.batch();
      int batchCount = 0;

      for (final doc in spaceQuery.docs) {
        try {
          final data = doc.data();

          // Check if document is empty (has no fields)
          if (data == null || (data is Map && data.isEmpty)) {
            print(
                'Empty document found: ${doc.id} in spaces/$typePath/spaces');

            // Add to deletion batch
            batch.delete(doc.reference);
            emptyDocCount++;
            batchCount++;

            // Commit batch every 400 operations
            if (batchCount >= 400) {
              print('Committing batch of $batchCount deletes...');
              await batch.commit();
              batch = firestore.batch();
              batchCount = 0;
            }
          }
        } catch (e) {
          print('Error checking document ${doc.id}: $e');
        }
      }

      // Commit any remaining operations
      if (batchCount > 0) {
        print('Committing final batch of $batchCount deletes...');
        await batch.commit();
      }

      print(
          'Found and removed $emptyDocCount empty documents in spaces/$typePath/spaces');
      totalEmptyDocs += emptyDocCount;
      totalRemoved += emptyDocCount;
    } catch (e) {
      print('Error checking spaces/$typePath/spaces: $e');
    }
  }

  // Final summary
  print('');
  print('Cleanup summary:');
  print('- Total empty documents found and removed: $totalEmptyDocs');
}
