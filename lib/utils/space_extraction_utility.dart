import 'package:flutter/material.dart';
import 'package:hive_ui/services/space_event_service.dart';

/// Utility for manually triggering space extraction from events
class SpaceExtractionUtility {
  /// Trigger the extraction of spaces from all events in Firestore
  /// Returns the number of spaces extracted
  static Future<int> extractSpacesFromAllEvents(BuildContext context) async {
    try {
      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Extracting Spaces'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Processing events and generating spaces...'),
            ],
          ),
        ),
      );

      // Start extraction process
      final processedSpaces =
          await SpaceEventService.processAllExistingEvents();

      // Close the dialog
      if (!context.mounted) return 0;
      Navigator.of(context, rootNavigator: true).pop();

      // Show success dialog
      if (!context.mounted) return processedSpaces;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Extraction Complete'),
          content: Text(
              'Successfully extracted $processedSpaces spaces from events.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      return processedSpaces;
    } catch (e) {
      // Close loading dialog if open
      if (!context.mounted) return 0;
      Navigator.of(context, rootNavigator: true).pop();

      // Show error dialog
      if (!context.mounted) return 0;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Extraction Failed'),
          content: Text('Error extracting spaces: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );

      return 0;
    }
  }
}
