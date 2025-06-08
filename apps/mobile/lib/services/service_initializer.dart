import 'package:flutter/material.dart';
import 'package:hive_ui/services/optimized_club_adapter.dart';

/// Initializes all optimized services for the app
class ServiceInitializer {
  static bool _isInitialized = false;

  /// Initialize all services required by the app
  static Future<void> initializeServices() async {
    if (_isInitialized) return;

    try {
      debugPrint('Initializing optimized service layer...');

      // Initialize the optimized club adapter
      await OptimizedClubAdapter.initialize();

      _isInitialized = true;
      debugPrint('Service initialization complete');
    } catch (e) {
      debugPrint('Error initializing services: $e');
      // We don't rethrow here to prevent app crashes on startup
      // The app can still function with default implementations
    }
  }

  /// This method should be called in your main.dart before runApp()
  static Future<void> initializeApp() async {
    // Initialize services
    await initializeServices();
  }
}
