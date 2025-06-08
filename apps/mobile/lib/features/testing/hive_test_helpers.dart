import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/core/cache/hive_initialize.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive_ui/features/testing/ci_config.dart';

/// Helper functions for working with Hive in tests
class HiveTestHelpers {
  /// Set up Hive for a test group
  static Future<void> setUpHiveForTesting() async {
    try {
      debugPrint('🧪 Setting up Hive for testing...');
      await HiveInitialize.initForTesting();
      debugPrint('✅ Hive test setup complete');
    } catch (e) {
      debugPrint('❌ Failed to set up Hive for testing: $e');
      rethrow;
    }
  }
  
  /// Clean up Hive after a test group
  static Future<void> tearDownHiveForTesting() async {
    try {
      debugPrint('🧪 Tearing down Hive testing environment...');
      await HiveInitialize.close();
      debugPrint('✅ Hive test teardown complete');
    } catch (e) {
      debugPrint('❌ Failed to tear down Hive test environment: $e');
      // Don't rethrow here, as this is cleanup code that shouldn't fail tests
    }
  }
  
  /// Create a unique test box name
  /// 
  /// Use this to avoid test interference when multiple tests use the same box name.
  static String getUniqueBoxName(String baseName) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_$timestamp';
  }
  
  /// Skip test if Hive tests are disabled in CI config
  /// 
  /// Usage:
  /// ```dart
  /// testWidgets('my hive test', (tester) async {
  ///   if (HiveTestHelpers.shouldSkipHiveTests()) return;
  ///   // test body
  /// });
  /// ```
  static bool shouldSkipHiveTests() {
    final shouldSkip = !CIConfig.includeHiveTests;
    if (shouldSkip) {
      debugPrint('⏩ Skipping Hive test as they are disabled in the current configuration');
    }
    return shouldSkip;
  }
  
  /// Create a test box with sample data
  /// 
  /// Useful for quickly setting up test data in Hive.
  static Future<Box<Map>> createTestBox(
    String boxName, {
    Map<String, Map<String, dynamic>>? testData,
  }) async {
    final box = await Hive.openBox<Map>(boxName);
    
    // Clear box just in case it already exists
    await box.clear();
    
    // Add test data if provided
    if (testData != null) {
      for (final entry in testData.entries) {
        await box.put(entry.key, entry.value);
      }
    }
    
    return box;
  }
  
  /// Register all test-specific adapters
  /// 
  /// This should reflect the adapters registered in the main app,
  /// but may include mock versions for testing.
  static void registerTestAdapters() {
    // Example:
    // if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
    //   Hive.registerAdapter(UserAdapter());
    // }
  }
  
  /// Create test setup for a golden test group
  static Future<void> goldenTestSetup() async {
    // Initialize Hive for testing
    await setUpHiveForTesting();
    
    // Register any needed adapters
    registerTestAdapters();
    
    // Load any fixtures needed for golden tests
    await _loadGoldenFixtures();
  }
  
  /// Load any fixtures needed for golden tests
  static Future<void> _loadGoldenFixtures() async {
    // Load any mock data or assets needed for golden tests
  }
}

/// Utility extension for working with Hive boxes in tests
extension HiveBoxTestExtension<T> on Box<T> {
  /// Clear the box and add sample items
  Future<void> populateWithTestData(Map<dynamic, T> testData) async {
    await clear();
    await putAll(testData);
  }
  
  /// Verify the box contains expected values
  void expectBoxContains(Map<dynamic, dynamic> expectedData) {
    for (final entry in expectedData.entries) {
      final actual = get(entry.key);
      // Use expect from flutter_test
      expect(actual, entry.value, reason: 'Box should contain correct value for key ${entry.key}');
    }
  }
  
  /// Verify the box has expected keys
  void expectBoxHasKeys(List<dynamic> expectedKeys) {
    for (final key in expectedKeys) {
      // Use expect from flutter_test
      expect(containsKey(key), true, reason: 'Box should contain key $key');
    }
  }
  
  /// Verify the box does not have certain keys
  void expectBoxDoesNotHaveKeys(List<dynamic> unexpectedKeys) {
    for (final key in unexpectedKeys) {
      // Use expect from flutter_test
      expect(containsKey(key), false, reason: 'Box should not contain key $key');
    }
  }
} 