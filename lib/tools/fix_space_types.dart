import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A utility script to fix space types in the spaces collection.
///
/// This script will analyze all spaces in the spaces collection and set
/// their spaceType field based on the name and description.
///
/// Run with: flutter run -d windows lib/tools/fix_space_types.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('==================================================');
  print('  HIVE UI - Space Type Fixer');
  print('==================================================');
  print('');
  print('This utility will analyze all spaces in the spaces collection');
  print('and update their spaceType field based on name and description.');
  print('');

  print('Press any key to begin or Ctrl+C to cancel...');
  await stdin.first;

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting space type analysis...');
    print('');

    await fixSpaceTypes();

    print('');
    print('Operation completed successfully.');
    print('');
    print('Press any key to exit...');
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete operation:');
    print(e);
    print('');
    print('Stack trace:');
    print(stackTrace);
    print('');
    print('Press any key to exit...');
    await stdin.first;
    exit(1);
  }
}

/// Fix space types by analyzing space names and descriptions
Future<void> fixSpaceTypes() async {
  final firestore = FirebaseFirestore.instance;
  final spacesCollection = firestore.collection('spaces');

  // Fetch all spaces
  print('Fetching spaces from Firestore...');
  final spacesQuery = await spacesCollection.get();
  print('Found ${spacesQuery.docs.length} spaces');

  // Create batch for updates
  var batch = firestore.batch();
  int batchCount = 0;
  int totalUpdated = 0;

  // Track stats
  final Map<SpaceType, int> typeStats = {
    SpaceType.studentOrg: 0,
    SpaceType.universityOrg: 0,
    SpaceType.campusLiving: 0,
    SpaceType.fraternityAndSorority: 0,
    SpaceType.other: 0,
  };

  // Process each space
  for (final spaceDoc in spacesQuery.docs) {
    // Skip documents that are not actual spaces
    if (!spaceDoc.id.startsWith('space_')) {
      print('Skipping non-space document: ${spaceDoc.id}');
      continue;
    }

    final spaceData = spaceDoc.data();
    final String name = spaceData['name'] as String? ?? '';
    final String description = spaceData['description'] as String? ?? '';

    // Determine space type
    SpaceType spaceType;

    // First check if it already has a type
    final String existingType = spaceData['spaceType'] as String? ?? '';
    if (existingType.isNotEmpty) {
      spaceType = SpaceTypeExtension.fromFirestoreValue(existingType);
    } else {
      // Determine type based on name and description
      spaceType = _determineSpaceType(name, description, spaceDoc.id);
    }

    print('Space: ${spaceDoc.id} - Type: ${spaceType.displayName}');
    typeStats[spaceType] = (typeStats[spaceType] ?? 0) + 1;

    // Update space type
    batch.update(spaceDoc.reference, {
      'spaceType': spaceType.toFirestoreValue(),
    });

    batchCount++;
    totalUpdated++;

    // Commit batch every 500 updates
    if (batchCount >= 500) {
      print('Committing batch of $batchCount updates...');
      await batch.commit();
      batch = firestore.batch();
      batchCount = 0;
    }
  }

  // Commit any remaining updates
  if (batchCount > 0) {
    print('Committing final batch of $batchCount updates...');
    await batch.commit();
  }

  // Print statistics
  print('');
  print('Updated $totalUpdated spaces with correct types');
  print('');
  print('Space type distribution:');
  print('  - Student Organizations: ${typeStats[SpaceType.studentOrg]}');
  print('  - University Organizations: ${typeStats[SpaceType.universityOrg]}');
  print('  - Campus Living: ${typeStats[SpaceType.campusLiving]}');
  print(
      '  - Fraternity & Sorority: ${typeStats[SpaceType.fraternityAndSorority]}');
  print('  - Other: ${typeStats[SpaceType.other]}');
}

/// Determine space type based on name and description
SpaceType _determineSpaceType(String name, String description, String spaceId) {
  final String lowerName = name.toLowerCase();
  final String lowerDescription = description.toLowerCase();
  final String combinedText = '$lowerName $lowerDescription $spaceId';

  // Greek organization check
  if (_containsAny(combinedText, [
    'fraternity',
    'sorority',
    'frat',
    'greek',
    'alpha',
    'beta',
    'gamma',
    'delta',
    'epsilon',
    'zeta',
    'eta',
    'theta',
    'iota',
    'kappa',
    'lambda',
    'mu',
    'nu',
    'xi',
    'omicron',
    'pi',
    'rho',
    'sigma',
    'tau',
    'upsilon',
    'phi',
    'chi',
    'psi',
    'omega'
  ])) {
    return SpaceType.fraternityAndSorority;
  }

  // Campus living check
  if (_containsAny(combinedText, [
    'residence',
    'housing',
    'dormitory',
    'dorm',
    'hall',
    'apartment',
    'living',
    'community',
    'village',
    'quarter',
    'suite'
  ])) {
    return SpaceType.campusLiving;
  }

  // University org check
  if (_containsAny(combinedText, [
        'department',
        'division',
        'faculty',
        'school',
        'college',
        'institute',
        'center',
        'academy',
        'program',
        'education',
        'academic',
        'administration',
        'research',
        'university',
        'office of',
        'services'
      ]) ||
      lowerName.contains('university') ||
      lowerDescription.contains('university')) {
    return SpaceType.universityOrg;
  }

  // Student organization check (default for most spaces)
  if (_containsAny(combinedText, [
        'student',
        'club',
        'society',
        'association',
        'team',
        'group',
        'council',
        'committee',
        'undergraduate',
        'graduate',
        'members',
        'honors',
        'organization'
      ]) ||
      spaceId.contains('club') ||
      spaceId.contains('association') ||
      spaceId.contains('society') ||
      spaceId.contains('team')) {
    return SpaceType.studentOrg;
  }

  // Default to Other
  return SpaceType.other;
}

bool _containsAny(String text, List<String> keywords) {
  for (final keyword in keywords) {
    if (text.contains(keyword)) {
      return true;
    }
  }
  return false;
}
