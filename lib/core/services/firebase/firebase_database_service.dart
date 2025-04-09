import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/utils/realtime_db_windows_fix.dart';

/// Service for handling Firebase Realtime Database operations
class FirebaseDatabaseService {
  final FirebaseDatabase _database;
  
  FirebaseDatabaseService({FirebaseDatabase? database}) 
      : _database = database ?? FirebaseDatabase.instance;
  
  /// Initialize the Firebase Database service
  Future<void> initialize() async {
    try {
      // Apply Windows-specific fixes if needed
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        RealtimeDbWindowsFix.initialize();
      }
      
      // Configure database settings
      _database.setPersistenceEnabled(
        defaultTargetPlatform != TargetPlatform.windows
      );
      
      debugPrint('✅ Firebase Database service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing Firebase Database service: $e');
    }
  }
  
  /// Get a database reference
  DatabaseReference ref(String path) {
    return _database.ref(path);
  }
  
  /// Set data at a specific path
  Future<void> setData(String path, dynamic data) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await RealtimeDbWindowsFix.safeSet(_database.ref(path), data);
    } else {
      await _database.ref(path).set(data);
    }
  }
  
  /// Update data at a specific path
  Future<void> updateData(String path, Map<String, dynamic> data) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await RealtimeDbWindowsFix.safeUpdate(_database.ref(path), data);
    } else {
      await _database.ref(path).update(data);
    }
  }
  
  /// Remove data at a specific path
  Future<void> removeData(String path) async {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      await RealtimeDbWindowsFix.safeRemove(_database.ref(path));
    } else {
      await _database.ref(path).remove();
    }
  }
  
  /// Listen to data at a specific path
  Stream<DatabaseEvent> onValue(String path) {
    return _database.ref(path).onValue;
  }
  
  /// Get data once from a specific path
  Future<DataSnapshot> getData(String path) async {
    return await _database.ref(path).get();
  }
  
  /// Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await setData('users/$userId/online', isOnline);
      await setData('users/$userId/lastSeen', ServerValue.timestamp);
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }
}

/// Provider for the Firebase Database service
final firebaseDatabaseServiceProvider = Provider<FirebaseDatabaseService>((ref) {
  return FirebaseDatabaseService();
}); 