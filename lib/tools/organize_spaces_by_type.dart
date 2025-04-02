import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to reorganize spaces in Firestore based on their spaceType.
///
/// This script will:
/// 1. Read all spaces from the root 'spaces' collection
/// 2. Create type-specific collections:
///    - spaces/student_organizations/spaces
///    - spaces/university_organizations/spaces
///    - spaces/campus_living/spaces
///    - spaces/fraternity_and_sorority/spaces
///    - spaces/other/spaces
/// 3. Copy each space to its appropriate type subcollection
/// 4. Maintain space IDs and all data
///
/// Run with: flutter run -d windows lib/tools/organize_spaces_by_type.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Space Structure Migrator');
  print('==================================================');
  print('');
  print('This utility will reorganize spaces in Firestore based on');
  print(
      'their spaceType field, moving them into type-specific subcollections.');
  print('');
  print('The new structure will be:');
  print('  - spaces/');
  print('    - student_organizations/spaces/');
  print('    - university_organizations/spaces/');
  print('    - campus_living/spaces/');
  print('    - fraternity_and_sorority/spaces/');
  print('    - other/spaces/');
  print('');

  print('Starting automatically in 3 seconds...');
  await Future.delayed(const Duration(seconds: 3));

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting space reorganization...');
    print('');

    await organizeSpacesByType();

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

/// Get the subcollection path for a given space type
String getSubcollectionPath(SpaceType spaceType) {
  switch (spaceType) {
    case SpaceType.studentOrg:
      return 'student_organizations';
    case SpaceType.universityOrg:
      return 'university_organizations';
    case SpaceType.campusLiving:
      return 'campus_living';
    case SpaceType.fraternityAndSorority:
      return 'fraternity_and_sorority';
    case SpaceType.hiveExclusive:
      return 'hive_exclusive';
    case SpaceType.other:
      return 'other';
  }
}

/// Reorganize spaces based on their spaceType
Future<void> organizeSpacesByType() async {
  final firestore = FirebaseFirestore.instance;
  final spacesCollection = firestore.collection('spaces');

  // Fetch all spaces
  print('Fetching spaces from Firestore...');
  final spacesQuery = await spacesCollection.get();
  print('Found ${spacesQuery.docs.length} spaces');

  // Initialize counters for statistics
  Map<SpaceType, int> migratedCounts = {
    SpaceType.studentOrg: 0,
    SpaceType.universityOrg: 0,
    SpaceType.campusLiving: 0,
    SpaceType.fraternityAndSorority: 0,
    SpaceType.hiveExclusive: 0,
    SpaceType.other: 0,
  };

  int successful = 0;
  int failed = 0;

  // Process each space
  for (final spaceDoc in spacesQuery.docs) {
    try {
      // Skip documents that are not actual spaces
      if (!spaceDoc.id.startsWith('space_')) {
        print('Skipping non-space document: ${spaceDoc.id}');
        continue;
      }

      final spaceData = spaceDoc.data();

      // Get space type from document
      final String spaceTypeStr = spaceData['spaceType'] as String? ?? 'other';
      final SpaceType spaceType =
          SpaceTypeExtension.fromFirestoreValue(spaceTypeStr);

      // Get target subcollection path
      final String typeCollection = getSubcollectionPath(spaceType);

      // Create reference to destination
      final targetDocRef = firestore
          .collection('spaces')
          .doc(typeCollection)
          .collection('spaces')
          .doc(spaceDoc.id);

      // Copy the space to the new location
      await targetDocRef.set(spaceData);

      print('Migrated ${spaceDoc.id} to spaces/$typeCollection/spaces/');
      migratedCounts[spaceType] = (migratedCounts[spaceType] ?? 0) + 1;
      successful++;

      // Optional: You could delete the original document, but it's safer to do this
      // in a separate pass after validating migration success
      // await spaceDoc.reference.delete();
    } catch (e) {
      print('ERROR migrating ${spaceDoc.id}: $e');
      failed++;
    }
  }

  // Print summary
  print('');
  print('Migration completed:');
  print('- Successfully migrated: $successful spaces');
  print('- Failed: $failed spaces');
  print('');
  print('Spaces by type:');
  print(
      '- Student Organizations: ${migratedCounts[SpaceType.studentOrg]} spaces');
  print(
      '- University Organizations: ${migratedCounts[SpaceType.universityOrg]} spaces');
  print('- Campus Living: ${migratedCounts[SpaceType.campusLiving]} spaces');
  print(
      '- Fraternity & Sorority: ${migratedCounts[SpaceType.fraternityAndSorority]} spaces');
  print('- Hive Exclusive: ${migratedCounts[SpaceType.hiveExclusive]} spaces');
  print('- Other: $migratedCounts[SpaceType.other] spaces');

  print('');
  print(
      'IMPORTANT: This script has only copied the spaces to the new locations.');
  print('The original spaces collection still contains all the spaces.');
  print('Once you have verified the migration is successful, you can run a');
  print(
      'cleanup script to remove the original spaces from the root collection.');
}
