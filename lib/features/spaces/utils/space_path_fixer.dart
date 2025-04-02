import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/models/space.dart';
import 'package:hive_ui/models/space_metrics.dart';
import 'package:hive_ui/models/space_type.dart';
import 'package:hive_ui/models/organization.dart';

/// Utility class to help with the nested spaces path issue
class SpacePathFixer {
  /// Check and fix spaces path structure - spaces/(type)/spaces
  static Future<void> verifySpacesStructure() async {
    final firestore = FirebaseFirestore.instance;

    debugPrint('\n=== CHECKING SPACES COLLECTION STRUCTURE ===\n');

    // Check each type collection
    final typeCollections = [
      'student_organizations',
      'university_organizations',
      'campus_living',
      'fraternity_and_sorority',
      'other'
    ];

    for (final type in typeCollections) {
      debugPrint('\n--- Checking $type ---');

      try {
        // Check if type document exists
        final typeDoc = await firestore.collection('spaces').doc(type).get();
        if (!typeDoc.exists) {
          debugPrint('Document spaces/$type does not exist!');
          continue;
        }

        // Check the correct path: spaces/(type)/spaces/
        final spacesCollection =
            firestore.collection('spaces').doc(type).collection('spaces');
        final spacesSnapshot = await spacesCollection.get();

        debugPrint(
            '✓ Found ${spacesSnapshot.docs.length} spaces in spaces/$type/spaces');

        // Show sample spaces
        if (spacesSnapshot.docs.isNotEmpty) {
          final sample = spacesSnapshot.docs.take(2).toList();
          for (final doc in sample) {
            debugPrint('  - ${doc.id}: ${doc.data()['name'] ?? 'Unnamed'}');
          }
        } else {
          debugPrint('No spaces found in spaces/$type/spaces');
        }
      } catch (e) {
        debugPrint('✗ Error checking collection: $e');
      }
    }

    // Check root level collection
    try {
      final rootSpaces = await firestore.collection('spaces').get();
      final typeDocsCount = typeCollections.length;
      final actualSpacesCount = rootSpaces.docs.length - typeDocsCount;

      debugPrint('\n--- Root Spaces Collection ---');
      debugPrint(
          'Root spaces collection has ${rootSpaces.docs.length} documents');
      debugPrint(
          'After excluding type docs: $actualSpacesCount potential direct spaces');

      if (actualSpacesCount > 0) {
        int count = 0;
        for (final doc in rootSpaces.docs) {
          if (!typeCollections.contains(doc.id)) {
            count++;
            if (count <= 3) {
              debugPrint('  - ${doc.id}: ${doc.data()['name'] ?? 'Unnamed'}');
            }
          }
        }
      }
    } catch (e) {
      debugPrint('✗ Error checking root spaces: $e');
    }

    debugPrint('\n=== FINISHED CHECKING SPACES STRUCTURE ===\n');
  }

  /// Get spaces from the specified type path
  static Future<List<Space>> getSpacesWithPathDetection(
    String typePath, {
    bool includePrivate = true, // Default to showing all spaces
  }) async {
    final firestore = FirebaseFirestore.instance;
    final List<Space> spaces = [];

    try {
      // Check if type collection exists
      final typeDoc = await firestore.collection('spaces').doc(typePath).get();
      if (!typeDoc.exists) {
        debugPrint('Type collection does not exist: $typePath');
        return [];
      }

      // First try the regular structure: spaces/[type]/spaces
      debugPrint('Checking regular path: spaces/$typePath/spaces');
      Query regularCollection = firestore
          .collection('spaces')
          .doc(typePath)
          .collection('spaces')
          .where(FieldPath.documentId,
              isNotEqualTo: 'spaces') // Filter out 'spaces' document
          .orderBy(FieldPath
              .documentId); // Need to order by the same field used in where
              
      // Filter private spaces if needed
      if (!includePrivate) {
        regularCollection = regularCollection.where('isPrivate', isEqualTo: false);
      }
      
      // Apply limit
      regularCollection = regularCollection.limit(50);

      final regularSnapshot = await regularCollection.get();
      debugPrint(
          'Found ${regularSnapshot.docs.length} spaces in regular path spaces/$typePath/spaces');

      // Process regular path documents
      for (final doc in regularSnapshot.docs) {
        try {
          // Skip documents that might be type collections or have special names
          if (doc.id == 'TypeofSpace' || doc.id == 'spaces') {
            debugPrint('Skipping special document: ${doc.id}');
            continue;
          }

          final space = _parseSpaceFromFirestore(doc, typePath);
          spaces.add(space);
        } catch (e) {
          debugPrint('Error parsing space from regular path: $e');
        }
      }

      // If no or few spaces found in regular path, check nested structure
      if (spaces.length < 5) {
        debugPrint(
            'Checking nested path: spaces/$typePath/spaces/spaces/spaces');
        // Check if there's a "spaces" document in the first level
        final spacesDoc = await firestore
            .collection('spaces')
            .doc(typePath)
            .collection('spaces')
            .doc('spaces')
            .get();

        if (spacesDoc.exists) {
          // Query the nested structure
          Query nestedCollection = firestore
              .collection('spaces')
              .doc(typePath)
              .collection('spaces')
              .doc('spaces')
              .collection('spaces');
              
          // Filter private spaces if needed
          if (!includePrivate) {
            nestedCollection = nestedCollection.where('isPrivate', isEqualTo: false);
          }
          
          // Apply limit
          nestedCollection = nestedCollection.limit(50);

          final nestedSnapshot = await nestedCollection.get();
          debugPrint(
              'Found ${nestedSnapshot.docs.length} spaces in nested path spaces/$typePath/spaces/spaces/spaces');

          // Process nested path documents
          for (final doc in nestedSnapshot.docs) {
            try {
              if (doc.id == 'TypeofSpace' || doc.id == 'spaces') {
                debugPrint(
                    'Skipping special document in nested path: ${doc.id}');
                continue;
              }

              final space = _parseSpaceFromFirestore(doc, typePath);
              spaces.add(space);
            } catch (e) {
              debugPrint('Error parsing space from nested path: $e');
            }
          }
        }
      }

      // Print debugging info about retrieved spaces
      if (spaces.isNotEmpty) {
        debugPrint('Retrieved ${spaces.length} total spaces from $typePath:');
        for (final space in spaces.take(3)) {
          debugPrint('  - ${space.id}: ${space.name}');
        }
      } else {
        debugPrint('No spaces found for $typePath in any path structure');
      }

      return spaces;
    } catch (e) {
      debugPrint('Error getting spaces with path detection: $e');
      return [];
    }
  }

  /// Parse a Firestore document into a Space object
  static Space _parseSpaceFromFirestore(
      DocumentSnapshot doc, String collectionPath) {
    final data = doc.data() as Map<String, dynamic>;

    // Extract metrics
    final metricsData = data['metrics'] as Map<String, dynamic>? ?? {};
    final metrics = SpaceMetrics(
      spaceId: metricsData['spaceId'] ?? doc.id,
      memberCount: metricsData['memberCount'] ?? 0,
      activeMembers: metricsData['activeMembers'] ?? 0,
      weeklyEvents: metricsData['weeklyEvents'] ?? 0,
      monthlyEngagements: metricsData['monthlyEngagements'] ?? 0,
      lastActivity: metricsData['lastActivity'] != null
          ? (metricsData['lastActivity'] as Timestamp).toDate()
          : DateTime.now(),
      hasNewContent: metricsData['hasNewContent'] ?? false,
      isTrending: metricsData['isTrending'] ?? false,
      engagementScore: (metricsData['engagementScore'] ?? 0).toDouble(),
      isTimeSensitive: metricsData['isTimeSensitive'] ?? false,
      category: _stringToSpaceCategory(metricsData['category'] ?? 'suggested'),
      size: _stringToSpaceSize(metricsData['size'] ?? 'medium'),
      activeMembers24h: const [],
      activityScores: const {},
      connectedFriends: const [],
    );

    // Extract optional organization data
    Organization? organization;
    if (data['organization'] != null) {
      final orgData = data['organization'] as Map<String, dynamic>;
      organization = Organization(
        id: orgData['id'] ?? '',
        name: orgData['name'] ?? '',
        description: '',
        category: '',
        memberCount: 0,
        status: '',
        icon: Icons.group,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isVerified: orgData['isVerified'] ?? false,
        isOfficial: orgData['isOfficial'] ?? false,
      );
    }

    // Determine space type from collection path
    SpaceType spaceType = _getSpaceTypeFromPath(collectionPath);

    // Extract event IDs
    final List<String> eventIds = [];
    if (data['eventIds'] != null) {
      eventIds.addAll((data['eventIds'] as List).map((e) => e.toString()));
    }

    // Create the Space object
    return Space(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      icon: _stringToIconData(data['icon']) ?? Icons.group,
      metrics: metrics,
      imageUrl: data['imageUrl'],
      bannerUrl: data['bannerUrl'],
      organization: organization,
      tags: List<String>.from(data['tags'] ?? []),
      customData: Map<String, dynamic>.from(data['customData'] ?? {}),
      isJoined: data['isJoined'] ?? false,
      isPrivate: data['isPrivate'] ?? false,
      moderators: List<String>.from(data['moderators'] ?? []),
      admins: List<String>.from(data['admins'] ?? []),
      quickActions: Map<String, String>.from(data['quickActions'] ?? {}),
      relatedSpaceIds: List<String>.from(data['relatedSpaceIds'] ?? []),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      spaceType: spaceType,
      eventIds: eventIds,
    );
  }

  /// Helper to convert string to IconData
  static IconData? _stringToIconData(String? iconString) {
    if (iconString == null) return null;

    final parts = iconString.split(',');
    if (parts.length < 2) return Icons.group;

    // Instead of creating a new IconData instance, use predefined MaterialIcons
    final int codePoint = int.parse(parts[0]);

    // Match the code point to known Material Icons
    switch (codePoint) {
      case 0xe318:
        return Icons.group; // group icon
      case 0xe1a5:
        return Icons.business; // business icon
      case 0xe332:
        return Icons.home; // home icon
      case 0xe30e:
        return Icons.forum; // forum icon
      case 0xe0c9:
        return Icons.computer; // computer icon
      case 0xe8f8:
        return Icons.school; // school icon
      case 0xe3ab:
        return Icons.people; // people icon
      case 0xe639:
        return Icons.sports; // sports icon
      case 0xe430:
        return Icons.music_note; // music_note icon
      case 0xe40a:
        return Icons.palette; // palette icon
      case 0xe465:
        return Icons.science; // science icon
      case 0xe02f:
        return Icons.book; // book icon
      case 0xe03e:
        return Icons.celebration; // celebration icon
      default:
        return Icons.group; // default to group
    }
  }

  /// Helper to convert string to SpaceCategory
  static SpaceCategory _stringToSpaceCategory(String category) {
    switch (category.toLowerCase()) {
      case 'active':
        return SpaceCategory.active;
      case 'expanding':
        return SpaceCategory.expanding;
      case 'emerging':
        return SpaceCategory.emerging;
      case 'suggested':
      default:
        return SpaceCategory.suggested;
    }
  }

  /// Helper to convert string to SpaceSize
  static SpaceSize _stringToSpaceSize(String size) {
    switch (size.toLowerCase()) {
      case 'large':
        return SpaceSize.large;
      case 'small':
        return SpaceSize.small;
      case 'medium':
      default:
        return SpaceSize.medium;
    }
  }

  /// Get SpaceType from collection path
  static SpaceType _getSpaceTypeFromPath(String path) {
    switch (path) {
      case 'student_organizations':
        return SpaceType.studentOrg;
      case 'university_organizations':
        return SpaceType.universityOrg;
      case 'campus_living':
        return SpaceType.campusLiving;
      case 'fraternity_and_sorority':
        return SpaceType.fraternityAndSorority;
      case 'hive_exclusive':
        return SpaceType.hiveExclusive;
      default:
        return SpaceType.other;
    }
  }
}
