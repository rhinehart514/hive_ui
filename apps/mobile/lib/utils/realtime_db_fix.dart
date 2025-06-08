import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// This class provides fixes for Firebase Realtime Database across platforms
/// Ensures proper initialization and configuration for platform-specific issues
class RealtimeDatabaseFix {
  /// Initialize the Firebase Realtime Database with appropriate settings
  static void initialize() {
    try {
      debugPrint('Initializing Firebase Realtime Database for ${defaultTargetPlatform.toString()}');
      
      final instance = FirebaseDatabase.instance;
      
      // Apply platform-specific settings
      if (defaultTargetPlatform == TargetPlatform.android || 
          defaultTargetPlatform == TargetPlatform.iOS) {
        // Enable persistence for mobile platforms for offline support
        instance.setPersistenceEnabled(true);
        
        // Set optimal cache size for mobile
        instance.setPersistenceCacheSizeBytes(10 * 1024 * 1024); // 10MB
        
        debugPrint('Mobile-optimized Firebase Realtime Database configuration applied');
      } else {
        // For other platforms (Windows, macOS, etc.), disable persistence to avoid issues
        instance.setPersistenceEnabled(false);
        debugPrint('Desktop Firebase Realtime Database configuration applied');
      }
    } catch (e) {
      debugPrint('Error initializing Firebase Realtime Database: $e');
      // Log the error but continue execution
    }
  }
} 