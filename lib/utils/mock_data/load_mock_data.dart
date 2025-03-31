import 'package:flutter/material.dart';
import '../mock_data/mock_profiles.dart';

/// A utility class for loading mock data into the app for testing
class MockDataLoader {
  /// Loads mock profile data for testing Goose Chaser and suggested friends
  static Future<void> loadMockProfiles(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Loading Mock Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Uploading mock profiles to Firestore...'),
            ],
          ),
        ),
      );
      
      // Upload mock data to Firestore
      await MockProfileData.uploadMockDataToFirestore();
      
      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show success dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Mock Data Loaded'),
            content: const Text(
              'Mock profile data for Goose Chaser and suggested friends has been successfully loaded into Firestore.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (context.mounted) {
        Navigator.of(context).pop();
        
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error Loading Mock Data'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      
      debugPrint('Error loading mock data: $e');
    }
  }
} 