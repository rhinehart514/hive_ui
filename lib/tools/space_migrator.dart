import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/providers/space_providers.dart';
import 'package:hive_ui/services/space_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Utility class to migrate existing spaces data to Firestore
class SpaceMigrator {
  // Local key for tracking migration completion as a fallback
  static const String _prefMigrationCompleteKey = 'spaces_migration_complete';

  /// Migrates all existing spaces to Firestore
  static Future<String> migrateSpacesToFirestore(WidgetRef ref) async {
    try {
      debugPrint('Starting migration of spaces to Firestore...');
      int migrated = 0;
      int failed = 0;

      // First check if already migrated using local preferences
      final prefs = await SharedPreferences.getInstance();
      final localMigrationComplete =
          prefs.getBool(_prefMigrationCompleteKey) ?? false;

      if (localMigrationComplete) {
        debugPrint(
            'Migration already completed according to local preferences');
        return 'Migration already completed';
      }

      // Get all existing spaces from providers
      final spaces = await ref.read(spacesProvider.future);

      debugPrint('Found ${spaces.length} spaces to migrate');

      // Initialize Firestore settings first to optimize performance
      await SpaceService.initSettings();

      // Process in batches of 20 for better UI feedback
      for (var i = 0; i < spaces.length; i += 20) {
        final end = (i + 20 < spaces.length) ? i + 20 : spaces.length;
        final batch = spaces.sublist(i, end);

        debugPrint(
            'Migrating batch ${i ~/ 20 + 1}: ${batch.length} spaces (${i + 1}-$end of ${spaces.length})');

        // Use a Firestore batch for better performance and atomicity
        final writeBatch = FirebaseFirestore.instance.batch();
        final spacesRef = FirebaseFirestore.instance.collection('spaces');

        // Add each space to the batch
        for (final space in batch) {
          try {
            final docRef = spacesRef.doc(space.id);

            // Prepare space data
            final spaceData = {
              'id': space.id,
              'name': space.name,
              'description': space.description,
              'icon':
                  '${space.icon.codePoint},${space.icon.fontFamily},${space.icon.fontPackage}',
              'imageUrl': space.imageUrl,
              'bannerUrl': space.bannerUrl,
              'tags': space.tags,
              'customData': space.customData,
              'isPrivate': space.isPrivate,
              'isJoined': space.isJoined,
              'moderators': space.moderators,
              'admins': space.admins,
              'quickActions': space.quickActions,
              'relatedSpaceIds': space.relatedSpaceIds,
              'createdAt': Timestamp.fromDate(space.createdAt),
              'updatedAt': Timestamp.fromDate(space.updatedAt),
              'organization': space.organization != null
                  ? {
                      'id': space.organization!.id,
                      'name': space.organization!.name,
                      'isVerified': space.organization!.isVerified,
                      'isOfficial': space.organization!.isOfficial,
                    }
                  : null,
              'metrics': {
                'spaceId': space.metrics.spaceId,
                'memberCount': space.metrics.memberCount,
                'activeMembers': space.metrics.activeMembers,
                'weeklyEvents': space.metrics.weeklyEvents,
                'monthlyEngagements': space.metrics.monthlyEngagements,
                'lastActivity': space.metrics.lastActivity == null
                    ? null
                    : Timestamp.fromDate(space.metrics.lastActivity!),
                'hasNewContent': space.metrics.hasNewContent,
                'isTrending': space.metrics.isTrending,
                'engagementScore': space.metrics.engagementScore,
                'isTimeSensitive': space.metrics.isTimeSensitive,
                'size': space.metrics.size.toString().split('.').last,
                'category': space.metrics.category.toString().split('.').last,
              },
            };

            // Add to batch
            writeBatch.set(docRef, spaceData, SetOptions(merge: true));
            migrated++;
          } catch (e) {
            failed++;
            debugPrint('Failed to prepare space ${space.id} for batch: $e');
          }
        }

        // Commit the batch
        try {
          await writeBatch.commit();
          debugPrint('Successfully committed batch of ${batch.length} spaces');
        } catch (e) {
          debugPrint('Error committing batch: $e');

          // If batch fails, fall back to individual saves
          debugPrint('Falling back to individual saves...');
          for (final space in batch) {
            try {
              await SpaceService.saveSpace(space);
              migrated++;
              debugPrint('Individually migrated space: ${space.id}');
            } catch (e) {
              failed++;
              debugPrint(
                  'Failed to individually migrate space ${space.id}: $e');
            }
          }
        }
      }

      // Migration complete
      final result =
          'Migration complete! Migrated $migrated spaces, failed $failed spaces.';
      debugPrint(result);

      // Mark migration as complete in both Firestore and local preferences
      await _markMigrationComplete();

      // Update local preferences as a fallback
      await prefs.setBool(_prefMigrationCompleteKey, true);

      return result;
    } catch (e) {
      final errorMsg = 'Error during space migration: $e';
      debugPrint(errorMsg);
      return errorMsg;
    }
  }

  /// Checks if migration has been completed
  static Future<bool> isMigrationComplete() async {
    try {
      // First check local preferences as fallback
      final prefs = await SharedPreferences.getInstance();
      final localMigrationComplete =
          prefs.getBool(_prefMigrationCompleteKey) ?? false;

      if (localMigrationComplete) {
        debugPrint('Migration complete according to local preferences');
        return true;
      }

      // Then check Firestore
      try {
        final doc = await FirebaseFirestore.instance
            .collection('metadata')
            .doc('space_migration')
            .get();

        final firestoreMigrationComplete =
            doc.exists && doc.data()?['completed'] == true;

        // If Firestore says complete, update local preferences
        if (firestoreMigrationComplete) {
          await prefs.setBool(_prefMigrationCompleteKey, true);
        }

        return firestoreMigrationComplete;
      } catch (e) {
        debugPrint('Error checking migration status in Firestore: $e');
        // If we can't access Firestore, return local preference value
        return localMigrationComplete;
      }
    } catch (e) {
      debugPrint('Error checking migration status: $e');
      // If we can't access Firestore yet, assume migration is not complete
      return false;
    }
  }

  /// Marks the migration as complete
  static Future<void> _markMigrationComplete() async {
    // Update local preferences first
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefMigrationCompleteKey, true);
      debugPrint('Migration marked as complete in local preferences');
    } catch (e) {
      debugPrint('Error saving migration status to preferences: $e');
    }

    // Then try to update Firestore
    try {
      await FirebaseFirestore.instance
          .collection('metadata')
          .doc('space_migration')
          .set({
        'completed': true,
        'timestamp': FieldValue.serverTimestamp(),
        'lastUpdated': DateTime.now().toIso8601String(),
      });

      debugPrint('Migration marked as complete in Firestore');
    } catch (e) {
      debugPrint('Error marking migration as complete in Firestore: $e');
      // Continue anyway since we've marked it in local preferences
    }
  }
}
