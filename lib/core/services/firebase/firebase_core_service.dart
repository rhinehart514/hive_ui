import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/firebase_options.dart';

/// Core Firebase service that handles initialization and common functionality
class FirebaseCoreService {
  static FirebaseCoreService? _instance;
  bool _isInitialized = false;

  FirebaseCoreService._();

  static FirebaseCoreService get instance {
    _instance ??= FirebaseCoreService._();
    return _instance!;
  }

  /// Initialize Firebase with retry mechanism
  Future<bool> initializeWithRetry({int maxRetries = 3}) async {
    if (_isInitialized) return true;

    int attempts = 0;
    while (attempts < maxRetries) {
      try {
        debugPrint('Firebase initialization attempt ${attempts + 1}/$maxRetries');
        
        // Check if Firebase is already initialized to prevent multiple initializations
        if (Firebase.apps.isNotEmpty) {
          debugPrint('Firebase already initialized, skipping initialization');
          _isInitialized = true;
          return true;
        }
        
        // Initialize Firebase with platform-specific options
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        
        debugPrint('Firebase successfully initialized');
        _isInitialized = true;
        return true;
      } catch (e) {
        attempts++;
        debugPrint('Firebase initialization failed (attempt $attempts): $e');
        
        if (attempts == maxRetries) {
          debugPrint('Failed to initialize Firebase after $maxRetries attempts');
          return false;
        }
        
        // Exponential backoff for retries
        final delay = Duration(seconds: 1 * attempts);
        debugPrint('Retrying in ${delay.inSeconds} seconds...');
        await Future.delayed(delay);
      }
    }
    return false;
  }

  /// Safely execute Firebase operations with error handling
  Future<T?> runWithErrorHandling<T>(Future<T> Function() operation, {
    String operationName = 'Firebase operation',
    T? defaultValue,
  }) async {
    if (!_isInitialized) {
      debugPrint('Firebase not initialized, cannot execute $operationName');
      return defaultValue;
    }
    
    try {
      return await operation();
    } catch (e) {
      debugPrint('Error during $operationName: $e');
      return defaultValue;
    }
  }

  bool get isInitialized => _isInitialized;
}

/// Provider for the Firebase core service
final firebaseCoreServiceProvider = Provider<FirebaseCoreService>((ref) {
  return FirebaseCoreService.instance;
});
