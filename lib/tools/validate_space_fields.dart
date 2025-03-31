import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/firebase_options.dart';

/// This script validates and ensures that all spaces in Firestore
/// have the proper fields required by the application.
void main() async {
  await validateSpaces();
}

/// Main validation function that can be called from other scripts
Future<void> validateSpaces() async {
  // Ensure widgets initialization for proper Flutter initialization
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('');
    print('Starting space validation process...');
    print('');

    // Validate and fix spaces
    final result = await validateAndFixSpaces();

    print('');
    print('Space validation completed.');
    print('Total spaces checked: ${result.totalChecked}');
    print('Spaces with all required fields: ${result.validSpaces}');
    print('Spaces fixed: ${result.fixedSpaces}');
    print('Spaces with errors: ${result.errorSpaces}');

    print('');
    print('Press any key to exit...');

    // Wait for user input before exiting
    await stdin.first;
    exit(0);
  } catch (e, stackTrace) {
    print('');
    print('ERROR: Failed to complete space validation:');
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

/// Results of the validation and fixing process
class ValidationResult {
  final int totalChecked;
  final int validSpaces;
  final int fixedSpaces;
  final int errorSpaces;

  ValidationResult({
    required this.totalChecked,
    required this.validSpaces,
    required this.fixedSpaces,
    required this.errorSpaces,
  });
}

/// Main function to validate and fix spaces in Firestore
Future<ValidationResult> validateAndFixSpaces() async {
  final firestore = FirebaseFirestore.instance;
  int totalChecked = 0;
  int validSpaces = 0;
  int fixedSpaces = 0;
  int errorSpaces = 0;

  // Define the type collections
  final typeCollections = [
    'student_organizations',
    'university_organizations',
    'campus_living',
    'fraternity_and_sorority',
    'other'
  ];

  print('Checking spaces structure...');

  // First check if the type collections exist
  for (final type in typeCollections) {
    print('\nChecking spaces/$type');

    try {
      // Check if type document exists
      final typeDoc = await firestore.collection('spaces').doc(type).get();
      if (!typeDoc.exists) {
        print('Creating type document: spaces/$type');
        await firestore.collection('spaces').doc(type).set({
          'name': type
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) =>
                  word.substring(0, 1).toUpperCase() + word.substring(1))
              .join(' '),
          'description': 'Collection for ${type.replaceAll('_', ' ')} spaces',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isTypeCollection': true,
        });
      }

      // Get spaces in this type
      final spaces = await firestore
          .collection('spaces')
          .doc(type)
          .collection('spaces')
          .get();

      print('Found ${spaces.docs.length} spaces in spaces/$type/spaces');

      // Process each space
      for (final spaceDoc in spaces.docs) {
        totalChecked++;
        final spaceId = spaceDoc.id;
        final spaceData = spaceDoc.data();

        try {
          // Validate the space has all required fields
          final missingFields = validateRequiredFields(spaceData);

          if (missingFields.isEmpty) {
            // Space has all required fields
            validSpaces++;
          } else {
            // Space is missing fields, fix it
            print(
                'Space $spaceId is missing fields: ${missingFields.join(', ')}');

            // Create fixed data with missing fields filled
            final fixedData =
                fixMissingFields(spaceId, spaceData, missingFields);

            // Update the space
            await spaceDoc.reference.set(fixedData, SetOptions(merge: true));

            print('Fixed space $spaceId');
            fixedSpaces++;
          }
        } catch (e) {
          print('Error processing space $spaceId: $e');
          errorSpaces++;
        }
      }
    } catch (e) {
      print('Error checking spaces/$type: $e');
    }
  }

  // Check root spaces collection (legacy)
  try {
    print('\nChecking root spaces collection');

    final rootSpaces = await firestore.collection('spaces').get();
    final actualSpaces = rootSpaces.docs
        .where((doc) => !typeCollections.contains(doc.id))
        .toList();

    print('Found ${actualSpaces.length} spaces in root collection');

    // Process each space
    for (final spaceDoc in actualSpaces) {
      totalChecked++;
      final spaceId = spaceDoc.id;
      final spaceData = spaceDoc.data();

      try {
        // Determine which type this space should be in
        final spaceType = spaceData['spaceType'] as String? ?? 'other';
        final targetType = mapSpaceTypeToCollection(spaceType);

        print('Space $spaceId should be in $targetType collection');

        // Validate the space has all required fields
        final missingFields = validateRequiredFields(spaceData);

        // Create fixed data with missing fields filled
        final fixedData = missingFields.isEmpty
            ? spaceData
            : fixMissingFields(spaceId, spaceData, missingFields);

        // Create the space in the proper type collection
        await firestore
            .collection('spaces')
            .doc(targetType)
            .collection('spaces')
            .doc(spaceId)
            .set(fixedData, SetOptions(merge: true));

        // Delete from root collection if successful
        await spaceDoc.reference.delete();

        print('Migrated space $spaceId to spaces/$targetType/spaces/$spaceId');
        fixedSpaces++;
      } catch (e) {
        print('Error processing root space $spaceId: $e');
        errorSpaces++;
      }
    }
  } catch (e) {
    print('Error checking root spaces: $e');
  }

  return ValidationResult(
    totalChecked: totalChecked,
    validSpaces: validSpaces,
    fixedSpaces: fixedSpaces,
    errorSpaces: errorSpaces,
  );
}

/// Maps a space type string to the appropriate collection
String mapSpaceTypeToCollection(String spaceType) {
  switch (spaceType) {
    case 'studentOrg':
      return 'student_organizations';
    case 'universityOrg':
      return 'university_organizations';
    case 'campusLiving':
      return 'campus_living';
    case 'fraternityAndSorority':
      return 'fraternity_and_sorority';
    default:
      return 'other';
  }
}

/// Validates that a space document has all required fields
/// Returns a list of missing field names
List<String> validateRequiredFields(Map<String, dynamic> spaceData) {
  final requiredFields = [
    'id',
    'name',
    'description',
    'spaceType',
    'createdAt',
    'updatedAt',
    'tags',
    'eventIds',
    'moderators',
    'admins',
    'relatedSpaceIds',
    'customData',
    'quickActions',
    'isJoined',
    'isPrivate',
    'metrics',
  ];

  // Check metrics subfields if metrics exists
  if (spaceData.containsKey('metrics') && spaceData['metrics'] is Map) {
    final metricsData = spaceData['metrics'] as Map<String, dynamic>;
    final requiredMetricsFields = [
      'memberCount',
      'activeMembers',
      'weeklyEvents',
      'monthlyEngagements',
      'engagementScore',
      'hasNewContent',
      'isTrending',
      'isTimeSensitive',
      'category',
      'size',
      'spaceId',
    ];

    for (final field in requiredMetricsFields) {
      if (!metricsData.containsKey(field)) {
        // Add as a nested field
        requiredFields.add('metrics.$field');
      }
    }
  } else {
    // If metrics doesn't exist or isn't a map, add it as a missing field
    if (!requiredFields.contains('metrics')) {
      requiredFields.add('metrics');
    }
  }

  // Return list of missing fields
  return requiredFields.where((field) {
    // Handle nested fields (e.g. metrics.memberCount)
    if (field.contains('.')) {
      final parts = field.split('.');
      final parentField = parts[0];
      final childField = parts[1];

      return !spaceData.containsKey(parentField) ||
          spaceData[parentField] is! Map ||
          !(spaceData[parentField] as Map).containsKey(childField);
    }

    // Handle regular fields
    return !spaceData.containsKey(field);
  }).toList();
}

/// Fixes missing fields in a space document
Map<String, dynamic> fixMissingFields(String spaceId,
    Map<String, dynamic> spaceData, List<String> missingFields) {
  // Start with a copy of the existing data
  final Map<String, dynamic> fixedData = Map<String, dynamic>.from(spaceData);

  // If metrics is missing completely, create it
  if (missingFields.contains('metrics')) {
    fixedData['metrics'] = {
      'memberCount': 0,
      'activeMembers': 0,
      'weeklyEvents': 0,
      'monthlyEngagements': 0,
      'engagementScore': 0.0,
      'hasNewContent': false,
      'isTrending': false,
      'isTimeSensitive': false,
      'category': 'suggested',
      'size': 'medium',
      'connectedFriends': <String>[],
      'spaceId': spaceId,
      'lastActivity': FieldValue.serverTimestamp(),
    };

    // Remove all metrics.* fields since we've added the whole metrics object
    missingFields.removeWhere((field) => field.startsWith('metrics.'));
  }

  // Fix other missing fields
  for (final field in missingFields) {
    if (field.contains('.')) {
      // Handle nested fields like metrics.memberCount
      final parts = field.split('.');
      final parentField = parts[0];
      final childField = parts[1];

      if (fixedData.containsKey(parentField) && fixedData[parentField] is Map) {
        // Parent exists, just add the child field
        final parent = fixedData[parentField] as Map<String, dynamic>;

        // Set default values based on field name
        switch (childField) {
          case 'memberCount':
          case 'activeMembers':
          case 'weeklyEvents':
          case 'monthlyEngagements':
            parent[childField] = 0;
            break;
          case 'engagementScore':
            parent[childField] = 0.0;
            break;
          case 'hasNewContent':
          case 'isTrending':
          case 'isTimeSensitive':
            parent[childField] = false;
            break;
          case 'category':
            parent[childField] = 'suggested';
            break;
          case 'size':
            parent[childField] = 'medium';
            break;
          case 'spaceId':
            parent[childField] = spaceId;
            break;
          case 'connectedFriends':
            parent[childField] = <String>[];
            break;
          case 'lastActivity':
            parent[childField] = FieldValue.serverTimestamp();
            break;
          default:
            parent[childField] = null;
        }
      }
    } else {
      // Handle top-level fields
      switch (field) {
        case 'id':
          fixedData['id'] = spaceId;
          break;
        case 'name':
          fixedData['name'] = 'Space $spaceId';
          break;
        case 'description':
          fixedData['description'] = 'Auto-fixed space description';
          break;
        case 'spaceType':
          fixedData['spaceType'] = 'other';
          break;
        case 'createdAt':
        case 'updatedAt':
          fixedData[field] = FieldValue.serverTimestamp();
          break;
        case 'tags':
        case 'eventIds':
        case 'moderators':
        case 'admins':
        case 'relatedSpaceIds':
          fixedData[field] = <String>[];
          break;
        case 'customData':
        case 'quickActions':
          fixedData[field] = <String, dynamic>{};
          break;
        case 'isJoined':
        case 'isPrivate':
          fixedData[field] = false;
          break;
        default:
          // For any other fields, set null as a safe default
          fixedData[field] = null;
      }
    }
  }

  return fixedData;
}
