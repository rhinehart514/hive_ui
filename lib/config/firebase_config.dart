import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';

/// Firebase configuration helper to ensure proper initialization
/// across all platforms.
class FirebaseConfig {
  /// Whether Firebase is in test mode
  /// Always false now that we use real Firebase on all platforms
  static bool get isMockMode => false;

  /// Initialize Firebase with the correct options for the current platform
  static Future<FirebaseApp> initializeFirebase() async {
    try {
      // Use platform-specific configuration
      debugPrint('Initializing Firebase with platform-specific configuration');
      final options = DefaultFirebaseOptions.currentPlatform;

      // Initialize Firebase with the selected options
      final app = await Firebase.initializeApp(options: options);
      debugPrint('Firebase initialized successfully: ${app.name}');

      return app;
    } catch (e) {
      debugPrint('Failed to initialize Firebase: $e');
      rethrow;
    }
  }
}
