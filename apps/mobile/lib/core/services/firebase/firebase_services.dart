export 'firebase_core_service.dart';
export 'firebase_analytics_service.dart';
export 'firebase_messaging_service.dart';
export 'firebase_database_service.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/firebase_init_tracker.dart';

/// Utility function to verify Firebase is initialized before using it
Future<bool> verifyFirebaseInitialization() async {
  // If already marked as initialized, check if it really is
  if (FirebaseInitTracker.isInitialized) {
    if (Firebase.apps.isNotEmpty) {
      return true;
    } else {
      // Firebase should be initialized but isn't - this is a problem
      debugPrint('⚠️ Firebase marked as initialized but Firebase.apps is empty. Reinitializing...');
    }
  }
  
  try {
    // Check if already initialized
    if (Firebase.apps.isNotEmpty) {
      debugPrint('Firebase already has initialized apps, no need to initialize again');
      FirebaseInitTracker.needsInitialization = false;
      FirebaseInitTracker.isInitialized = true;
      return true;
    }
    
    // Initialize Firebase - use real Firebase for all platforms
    debugPrint('Initializing Firebase from verification function');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Verify initialization succeeded
    if (Firebase.apps.isEmpty) {
      debugPrint('Firebase initialization failed - no apps created');
      FirebaseInitTracker.isInitialized = false;
      return false;
    }
    
    FirebaseInitTracker.needsInitialization = false;
    FirebaseInitTracker.isInitialized = true;
    debugPrint('Firebase initialized successfully from verification function with app count: ${Firebase.apps.length}');
    return true;
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
    FirebaseInitTracker.isInitialized = false;
    return false;
  }
}
