import 'dart:io';
import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

/// Fixes for Firebase Realtime Database on Windows platform
class RealtimeDbWindowsFix {
  // Flag to track if Windows fix has been applied
  static bool _initialized = false;

  /// Initialize with Windows-specific settings
  static void initialize() {
    if (!kIsWeb && Platform.isWindows && !_initialized) {
      _initialized = true;
      debugPrint('🔧 Applying Realtime Database Windows fixes...');
      
      try {
        // Disable persistence on Windows to avoid issues
        FirebaseDatabase.instance.setPersistenceEnabled(false);
        
        // Set the database to connect immediately
        FirebaseDatabase.instance.databaseURL = FirebaseDatabase.instance.databaseURL;
        
        // Set keep sync on disconnection to false
        FirebaseDatabase.instance.setPersistenceCacheSizeBytes(1000000); // minimal cache size
        
        debugPrint('✅ Applied Realtime Database Windows fixes');
      } catch (e) {
        debugPrint('⚠️ Error applying Realtime Database Windows fixes: $e');
      }
    }
  }
  
  /// Safely execute a Realtime Database operation with error handling
  static Future<T?> safeOperation<T>(Future<T> Function() operation, {T? defaultValue}) async {
    if (!kIsWeb && Platform.isWindows) {
      try {
        return await operation();
      } catch (e) {
        debugPrint('⚠️ Realtime Database operation failed: $e');
        return defaultValue;
      }
    } else {
      // For non-Windows platforms, just run the operation
      return operation();
    }
  }
  
  /// Safely set a value in the Realtime Database
  static Future<void> safeSet(DatabaseReference reference, dynamic value) async {
    await safeOperation(() => reference.set(value), defaultValue: null);
  }
  
  /// Safely update a value in the Realtime Database
  static Future<void> safeUpdate(DatabaseReference reference, Map<String, dynamic> value) async {
    await safeOperation(() => reference.update(value), defaultValue: null);
  }
  
  /// Safely remove a value from the Realtime Database
  static Future<void> safeRemove(DatabaseReference reference) async {
    await safeOperation(() => reference.remove(), defaultValue: null);
  }
} 