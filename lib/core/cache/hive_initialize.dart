import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

/// Manages Hive database initialization and provides testing utilities
class HiveInitialize {
  static bool _initialized = false;
  
  /// Initialize Hive for the application
  static Future<void> init() async {
    if (_initialized) return;
    
    try {
      debugPrint('🐝 HiveInitialize: Starting Hive initialization');
      
      // Initialize Hive with Flutter
      await Hive.initFlutter();
      
      // Register adapters here
      // Example: Hive.registerAdapter(UserAdapter());
      
      debugPrint('✅ HiveInitialize: Hive initialized successfully');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ HiveInitialize: Failed to initialize Hive: $e');
      rethrow;
    }
  }
  
  /// Initialize Hive for testing with a temporary directory
  static Future<void> initForTesting() async {
    if (_initialized) return;
    
    try {
      debugPrint('🧪 HiveInitialize: Starting Hive test initialization');
      
      // Get temp directory for testing
      final tempDir = await getTemporaryDirectory();
      
      // Initialize Hive with a specific test path
      Hive.init('${tempDir.path}/hive_test');
      
      // Register adapters here - same as production
      // Example: Hive.registerAdapter(UserAdapter());
      
      debugPrint('✅ HiveInitialize: Hive initialized for testing');
      _initialized = true;
    } catch (e) {
      debugPrint('❌ HiveInitialize: Failed to initialize Hive for testing: $e');
      rethrow;
    }
  }
  
  /// Close all Hive boxes and clean up resources
  static Future<void> close() async {
    if (!_initialized) return;
    
    try {
      await Hive.close();
      _initialized = false;
      debugPrint('🏁 HiveInitialize: Hive closed successfully');
    } catch (e) {
      debugPrint('❌ HiveInitialize: Error closing Hive: $e');
      rethrow;
    }
  }
  
  /// Delete all data in a specific box - useful for testing
  static Future<void> clearBox(String boxName) async {
    if (!_initialized) {
      debugPrint('⚠️ HiveInitialize: Cannot clear box, Hive not initialized');
      return;
    }
    
    try {
      final box = await Hive.openBox(boxName);
      await box.clear();
      await box.close();
      debugPrint('🧹 HiveInitialize: Box "$boxName" cleared');
    } catch (e) {
      debugPrint('❌ HiveInitialize: Error clearing box "$boxName": $e');
      rethrow;
    }
  }
} 