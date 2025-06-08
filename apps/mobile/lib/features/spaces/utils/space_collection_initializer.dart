import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility class to initialize space collections in Firestore
class SpaceCollectionInitializer {
  /// Create the required type collections in Firestore if they don't exist
  static Future<void> createSpaceTypeCollections() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      debugPrint('\n=== Creating space type collections ===\n');

      // Define the type collections to create
      final typeCollections = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];

      // Ensure each type collection exists
      for (final type in typeCollections) {
        final typeDocRef = firestore.collection('spaces').doc(type);
        final typeDoc = await typeDocRef.get();

        if (!typeDoc.exists) {
          debugPrint('Creating document for type: $type');
          batch.set(typeDocRef, {
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
            'type': type,
          });
        } else {
          debugPrint('Type collection already exists: $type');

          // Verify the type document has the correct structure
          final data = typeDoc.data() ?? {};
          if (!data.containsKey('isTypeCollection') ||
              !data['isTypeCollection']) {
            debugPrint('Updating type collection document: $type');
            batch.update(typeDocRef, {
              'isTypeCollection': true,
              'type': type,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Commit the batch
      await batch.commit();
      debugPrint('\n=== Finished creating space type collections ===\n');
    } catch (e) {
      debugPrint('Error creating space type collections: $e');
    }
  }

  /// Create a sample space in each type collection for testing
  static Future<void> createSampleSpaces() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      debugPrint('\n=== Creating sample spaces ===\n');

      // Define the type collections
      final typeCollections = [
        'student_organizations',
        'university_organizations',
        'campus_living',
        'fraternity_and_sorority',
        'other'
      ];

      // Create a sample space in each collection
      for (final type in typeCollections) {
        // First create the type doc if it doesn't exist
        final typeDocRef = firestore.collection('spaces').doc(type);
        final typeDoc = await typeDocRef.get();

        if (!typeDoc.exists) {
          debugPrint(
              'Type collection does not exist: $type, creating it first...');
          batch.set(typeDocRef, {
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

        // Now create a sample space in the spaces subcollection
        final sampleSpaceId = 'sample-${type.replaceAll('_', '-')}';
        final sampleSpaceRef = firestore
            .collection('spaces')
            .doc(type)
            .collection('spaces')
            .doc(sampleSpaceId);

        debugPrint('Creating sample space for type: $type');

        batch.set(sampleSpaceRef, {
          'id': sampleSpaceId,
          'name': '${_formatTypeCollectionName(type)} Sample',
          'description':
              'This is a sample space for ${type.replaceAll('_', ' ')}.',
          'spaceType': _getSpaceTypeValue(type),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'metrics': {
            'memberCount': 10,
            'activeMembers': 5,
            'weeklyEvents': 2,
            'monthlyEngagements': 25,
            'engagementScore': 75.0,
            'hasNewContent': true,
            'isTrending': false,
            'isTimeSensitive': false,
            'category': 'suggested',
            'size': 'medium',
          },
          'tags': ['sample', type.replaceAll('_', '-')],
          'isPrivate': false,
          'moderators': [],
          'admins': [],
        });
      }

      // Commit the batch
      await batch.commit();
      debugPrint('\n=== Finished creating sample spaces ===\n');
    } catch (e) {
      debugPrint('Error creating sample spaces: $e');
    }
  }

  /// Create a campus living sample space
  static Future<void> createCampusLivingSample() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      debugPrint('\n=== Creating campus living sample ===\n');

      // Target campus_living for sample
      const typeCollection = 'campus_living';

      // First create the type doc if it doesn't exist
      final typeDocRef = firestore.collection('spaces').doc(typeCollection);
      final typeDoc = await typeDocRef.get();

      if (!typeDoc.exists) {
        debugPrint(
            'Type collection does not exist: $typeCollection, creating it first...');
        batch.set(typeDocRef, {
          'name': 'Campus Living',
          'description': 'Collection for campus living spaces',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isTypeCollection': true,
        });
      }

      // Create a sample campus living space
      const sampleSpaceId = 'sample-campus-living';
      final sampleSpaceRef = firestore
          .collection('spaces')
          .doc(typeCollection)
          .collection('spaces')
          .doc(sampleSpaceId);

      debugPrint('Creating sample space for type: $typeCollection');

      batch.set(sampleSpaceRef, {
        'id': sampleSpaceId,
        'name': 'Campus Living Sample',
        'description': 'This is a sample campus living space.',
        'spaceType': 'campusLiving',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'metrics': {
          'memberCount': 15,
          'activeMembers': 8,
          'weeklyEvents': 3,
          'monthlyEngagements': 40,
          'engagementScore': 85.0,
          'hasNewContent': true,
          'isTrending': true,
          'isTimeSensitive': false,
          'category': 'active',
          'size': 'medium',
        },
        'tags': ['sample', 'campus-living'],
        'isPrivate': false,
        'moderators': [],
        'admins': [],
      });

      // Commit the batch
      await batch.commit();
      debugPrint('\n=== Finished creating campus living sample ===\n');
    } catch (e) {
      debugPrint('Error creating campus living sample: $e');
    }
  }

  /// Format a type collection name to a display name
  static String _formatTypeCollectionName(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.substring(0, 1).toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Get the corresponding SpaceType value for a type collection
  static String _getSpaceTypeValue(String type) {
    switch (type) {
      case 'student_organizations':
        return 'studentOrg';
      case 'university_organizations':
        return 'universityOrg';
      case 'campus_living':
        return 'campusLiving';
      case 'fraternity_and_sorority':
        return 'fraternityAndSorority';
      case 'other':
      default:
        return 'other';
    }
  }
}
