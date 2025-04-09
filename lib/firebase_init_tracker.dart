import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_ui/firebase_options.dart';
import 'package:hive_ui/stubs/firebase_windows_stubs.dart' as stubs;

/// Class to track Firebase initialization status globally
/// This ensures that Firebase is only initialized once across the app
class FirebaseInitTracker {
  /// Whether Firebase needs initialization
  static bool needsInitialization = true;
  
  /// Whether Firebase has been successfully initialized
  static bool isInitialized = false;
  
  /// Ensures Firebase is initialized before using it
  /// Can be called from anywhere in the app to guarantee Firebase is ready
  static Future<bool> ensureFirebaseInitialized() async {
    // If already initialized, return immediately
    if (isInitialized && !needsInitialization) {
      return true;
    }
    
    try {
      // Check if already initialized
      if (Firebase.apps.isNotEmpty) {
        debugPrint('Firebase already has initialized apps, no need to initialize again');
        needsInitialization = false;
        isInitialized = true;
        return true;
      }
    
      // Use real Firebase for all platforms
      debugPrint('Initializing Firebase from ensureFirebaseInitialized');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Verify initialization succeeded
      if (Firebase.apps.isEmpty) {
        debugPrint('Firebase initialization failed - no apps created');
        isInitialized = false;
        return false;
      }
      
      // Update state
      needsInitialization = false;
      isInitialized = true;
      debugPrint('Firebase successfully initialized with app count: ${Firebase.apps.length}');
      return true;
    } catch (e) {
      debugPrint('Error initializing Firebase: $e');
      isInitialized = false;
      return false;
    }
  }
  
  /// Creates a placeholder implementation of a repository during initialization
  /// 
  /// This allows the app to continue loading even when Firebase is not yet ready
  /// All operations that require Firebase will throw clear error messages
  static T createPlaceholderRepo<T>(
    String repoName, 
    T Function() createRealRepo, 
    T Function() createPlaceholder
  ) {
    if (isInitialized || (!needsInitialization && kIsWeb)) {
      // Firebase is ready, create the real repository
      try {
        return createRealRepo();
      } catch (e) {
        debugPrint('Error creating $repoName: $e');
        return createPlaceholder();
      }
    } else {
      // Firebase not ready, use placeholder
      debugPrint('Firebase not initialized for $repoName. Using placeholder.');
      return createPlaceholder();
    }
  }
} 