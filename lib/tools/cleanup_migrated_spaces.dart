import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to clean up the original space documents after migration.
///
/// This script will:
/// 1. Verify spaces were successfully migrated to type-specific subcollections
/// 2. Remove the original space documents from the root 'spaces' collection
///
/// IMPORTANT: Only run this after you have verified migration success!
///
/// Run with: flutter run -d windows lib/tools/cleanup_migrated_spaces.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Space Migration Cleanup');
  print('==================================================');
  print('');
  print('*** WARNING: This utility will DELETE spaces from the root');
  print('*** collection after verifying they exist in type-specific');
  print('*** subcollections. This operation is IRREVERSIBLE!');
  print('');

  print('Starting in 5 seconds (CTRL+C to cancel)...');
  await Future.delayed(const Duration(seconds: 5));

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting space cleanup...');
    print('');

    await cleanupMigratedSpaces();

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

/// Clean up original space documents after migration
Future<void> cleanupMigratedSpaces() async {
  final firestore = FirebaseFirestore.instance;
  final spacesCollection = firestore.collection('spaces');

  // Type subpaths
  final List<String> typeSubpaths = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other',
  ];

  // Fetch original spaces that need cleaning
  print('Fetching spaces from root collection...');
  final spacesQuery = await spacesCollection.get();
  print('Found ${spacesQuery.docs.length} spaces in root collection');

  // Track stats
  int verified = 0;
  int deleted = 0;
  int notMigrated = 0;
  int skipped = 0;

  // Create batch for deletes
  var batch = firestore.batch();
  int batchCount = 0;

  // Process each space
  for (final spaceDoc in spacesQuery.docs) {
    // Skip type documents or other documents
    if (typeSubpaths.contains(spaceDoc.id)) {
      print('Skipping type document: ${spaceDoc.id}');
      skipped++;
      continue;
    }

    // Skip documents that are not actual spaces
    if (!spaceDoc.id.startsWith('space_')) {
      print('Skipping non-space document: ${spaceDoc.id}');
      skipped++;
      continue;
    }

    // Check if this space has been migrated to any type subcollection
    bool isMigrated = false;

    for (final typePath in typeSubpaths) {
      final migratedRef = firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .doc(spaceDoc.id);

      final migratedDoc = await migratedRef.get();
      if (migratedDoc.exists) {
        isMigrated = true;
        verified++;
        break;
      }
    }

    if (isMigrated) {
      // Add to batch delete
      batch.delete(spaceDoc.reference);
      deleted++;
      batchCount++;
      print('Queued for deletion: ${spaceDoc.id}');

      // Commit batch every 400 deletes
      if (batchCount >= 400) {
        print('Committing batch of $batchCount deletes...');
        await batch.commit();
        batch = firestore.batch();
        batchCount = 0;
      }
    } else {
      print(
          'WARNING: Space ${spaceDoc.id} was not found in any subcollection! Skipping delete.');
      notMigrated++;
    }
  }

  // Commit any remaining deletes
  if (batchCount > 0) {
    print('Committing final batch of $batchCount deletes...');
    await batch.commit();
  }

  // Print summary
  print('');
  print('Cleanup completed:');
  print('- Verified migrated: $verified spaces');
  print('- Deleted from root: $deleted spaces');
  print('- Not migrated (kept): $notMigrated spaces');
  print('- Skipped non-spaces: $skipped documents');
}
