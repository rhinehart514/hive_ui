import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rss_service.dart';

/// Service for scheduling background tasks
/// This service ensures that RSS updates and other maintenance
/// tasks happen on a regular schedule rather than during normal
/// app operation
class SchedulerService {
  // Key for storing the last scheduled run timestamp
  static const String _lastRssUpdateKey = 'last_rss_update_timestamp';
  static const String _lastMaintenanceKey = 'last_maintenance_timestamp';

  // Weekly interval in milliseconds
  static const int _weeklyInterval = 7 * 24 * 60 * 60 * 1000; // 7 days

  // Daily interval in milliseconds
  static const int _dailyInterval = 24 * 60 * 60 * 1000; // 1 day

  /// Initialize the scheduler service and run any overdue tasks
  static Future<void> initialize() async {
    debugPrint('Initializing SchedulerService...');

    // Check and run weekly RSS update if needed
    await checkAndRunWeeklyRssUpdate();

    // Check and run daily maintenance if needed
    await checkAndRunDailyMaintenance();

    debugPrint('SchedulerService initialization complete');
  }

  /// Check if weekly RSS update is due and run it if needed
  static Future<bool> checkAndRunWeeklyRssUpdate() async {
    try {
      debugPrint('Checking if weekly RSS update is due...');

      // First check Firestore for the last sync time
      bool isFirestoreSyncNeeded = false;
      try {
        final metadataRef =
            FirebaseFirestore.instance.collection('metadata').doc('rss_sync');
        final metadataDoc = await metadataRef.get();

        if (metadataDoc.exists &&
            metadataDoc.data()?['last_sync_timestamp'] != null) {
          final timestamp =
              metadataDoc.data()?['last_sync_timestamp'] as Timestamp;
          final lastSync = timestamp.toDate();
          final now = DateTime.now();

          // If last sync was more than 7 days ago, it's due
          if (now.difference(lastSync).inDays >= 7) {
            debugPrint(
                'Firestore sync is due - last sync was ${now.difference(lastSync).inDays} days ago');
            isFirestoreSyncNeeded = true;
          } else {
            debugPrint(
                'Firestore sync is not due yet - last sync was ${now.difference(lastSync).inDays} days ago');
            return false; // Not due yet, skip RSS update
          }
        } else {
          // No record of previous sync, assume it's needed
          debugPrint('No record of previous Firestore sync, update is due');
          isFirestoreSyncNeeded = true;
        }
      } catch (e) {
        debugPrint('Error checking Firestore sync status: $e');
        // On error, fall back to checking SharedPreferences
      }

      // If Firestore indicates sync is needed, or we had an error checking it,
      // check the local shared preferences as a backup
      if (!isFirestoreSyncNeeded) {
        final prefs = await SharedPreferences.getInstance();
        final lastUpdateTimestamp = prefs.getInt(_lastRssUpdateKey) ?? 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // Check if a week has passed since the last update
        if ((now - lastUpdateTimestamp) >= _weeklyInterval) {
          debugPrint('Weekly RSS update is due based on local timestamp');
          isFirestoreSyncNeeded = true;
        } else {
          final nextUpdateDue = DateTime.fromMillisecondsSinceEpoch(
              lastUpdateTimestamp + _weeklyInterval);
          debugPrint(
              'Weekly RSS update not due yet based on local timestamp - next update scheduled for $nextUpdateDue');
          return false; // Not due yet, skip RSS update
        }
      }

      // If we got here, the update is due
      if (isFirestoreSyncNeeded) {
        // Run the RSS update in the background
        _runRssUpdate();

        // Update the timestamp before the task completes
        // This prevents multiple updates if the app is opened multiple times
        await _updateLastUpdateTimestamp();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking weekly RSS update schedule: $e');
      return false;
    }
  }

  /// Update timestamps to prevent duplicate runs
  static Future<void> _updateLastUpdateTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lastRssUpdateKey, now);

    // Also try to update Firestore
    try {
      final metadataRef =
          FirebaseFirestore.instance.collection('metadata').doc('scheduler');
      await metadataRef.set({
        'last_scheduled_rss_check': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating Firestore timestamp: $e');
    }
  }

  /// Check if daily maintenance is due and run it if needed
  static Future<bool> checkAndRunDailyMaintenance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastMaintenanceTimestamp = prefs.getInt(_lastMaintenanceKey) ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check if a day has passed since the last maintenance
      if ((now - lastMaintenanceTimestamp) >= _dailyInterval) {
        debugPrint('Daily maintenance is due');

        // Run maintenance tasks
        _runDailyMaintenance();

        // Update the timestamp
        await prefs.setInt(_lastMaintenanceKey, now);
        return true;
      } else {
        debugPrint('Daily maintenance not due yet');
        return false;
      }
    } catch (e) {
      debugPrint('Error checking daily maintenance schedule: $e');
      return false;
    }
  }

  /// Run the RSS update task in the background
  static Future<void> _runRssUpdate() async {
    debugPrint('Starting weekly RSS update task...');

    try {
      // Use the rate-limited version of batchSyncAllEventsToFirestore
      // It will check if a sync is needed based on the last sync time
      await RssService.batchSyncAllEventsToFirestore();
      debugPrint('Weekly RSS update completed successfully');
    } catch (e) {
      debugPrint('Error during weekly RSS update: $e');
    }
  }

  /// Run daily maintenance tasks
  static Future<void> _runDailyMaintenance() async {
    debugPrint('Starting daily maintenance tasks...');

    try {
      // No maintenance tasks yet, but we can add them here
      // Examples:
      // - Clean up expired events
      // - Update analytics
      // - Refresh cached data

      debugPrint('Daily maintenance completed successfully');
    } catch (e) {
      debugPrint('Error during daily maintenance: $e');
    }
  }

  /// Force run the RSS update regardless of schedule
  /// This is useful for manual updates or testing
  static Future<void> forceRunRssUpdate() async {
    debugPrint('Forcing RSS update task...');

    try {
      // Run the RSS update
      await RssService.batchSyncAllEventsToFirestore();

      // Update the timestamp
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          _lastRssUpdateKey, DateTime.now().millisecondsSinceEpoch);

      debugPrint('Forced RSS update completed successfully');
    } catch (e) {
      debugPrint('Error during forced RSS update: $e');
    }
  }
}
