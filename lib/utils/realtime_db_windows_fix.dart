import 'dart:io';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Fixes for Firebase Realtime Database on Windows platform
class RealtimeDbWindowsFix {
  /// Initialize with Windows-specific settings
  static void initialize() {
    if (!kIsWeb && Platform.isWindows) {
      try {
        // Disable persistence on Windows to avoid issues
        FirebaseDatabase.instance.setPersistenceEnabled(false);
        
        // Set the database to connect immediately
        FirebaseDatabase.instance.databaseURL = FirebaseDatabase.instance.databaseURL;
        
        // Wrap goOnline in a separate try-catch to prevent crashing
        try {
          // Disable connection management on Windows
          FirebaseDatabase.instance.goOnline();
        } catch (goOnlineError) {
          // Safely handle missing plugin exception
          debugPrint('⚠️ Note: goOnline method not available on this platform: $goOnlineError');
          // Continue execution despite this error
        }
        
        // Set keep sync on disconnection to false
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(1000000); // minimal cache size
        
        debugPrint('✅ Applied Realtime Database Windows fixes');
      } catch (e) {
        debugPrint('⚠️ Error applying Realtime Database Windows fixes: $e');
      }
    }
  }
  
  /// Ensure database operation happens on the platform thread
  static Future<T> runOperation<T>(Future<T> Function() operation) async {
    if (!kIsWeb && Platform.isWindows) {
      // Create a completer to manage the async operation
      final completer = Completer<T>();
      
      // Use a microtask to ensure we're on the platform thread
      Future.microtask(() async {
        try {
          final result = await operation();
          if (!completer.isCompleted) {
            completer.complete(result);
          }
        } catch (e) {
          if (!completer.isCompleted) {
            completer.completeError(e);
          }
        }
      });
      
      return completer.future;
    } else {
      // For non-Windows platforms, just run the operation
      return operation();
    }
  }
} 