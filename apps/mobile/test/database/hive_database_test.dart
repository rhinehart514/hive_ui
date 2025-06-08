import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_ui/features/testing/ci_config.dart';
import 'package:hive_ui/features/testing/hive_test_helpers.dart';

void main() {
  group('Hive Database Tests', () {
    // Set up Hive before all tests
    setUpAll(() async {
      // Skip this test group if Hive tests are disabled
      if (!CIConfig.includeHiveTests) {
        return;
      }
      
      await HiveTestHelpers.setUpHiveForTesting();
      HiveTestHelpers.registerTestAdapters();
    });
    
    // Clean up after all tests
    tearDownAll(() async {
      // Skip this test group if Hive tests are disabled
      if (!CIConfig.includeHiveTests) {
        return;
      }
      
      await HiveTestHelpers.tearDownHiveForTesting();
    });

    // Basic Hive functionality test
    test('Should store and retrieve values from Hive box', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      final boxName = HiveTestHelpers.getUniqueBoxName('test_box');
      final box = await Hive.openBox<String>(boxName);
      
      // Store values
      await box.put('key1', 'value1');
      await box.put('key2', 'value2');
      
      // Retrieve values
      expect(box.get('key1'), 'value1');
      expect(box.get('key2'), 'value2');
      expect(box.get('nonexistent'), null);
      
      // Clean up
      await box.close();
    });
    
    // Test with the extension methods
    test('Should use extension methods for validation', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      final boxName = HiveTestHelpers.getUniqueBoxName('extension_box');
      final box = await Hive.openBox<String>(boxName);
      
      // Populate with test data
      await box.populateWithTestData({
        'key1': 'value1',
        'key2': 'value2',
        'key3': 'value3',
      });
      
      // Verify using extension methods
      box.expectBoxContains({
        'key1': 'value1',
        'key2': 'value2',
      });
      
      box.expectBoxHasKeys(['key1', 'key2', 'key3']);
      box.expectBoxDoesNotHaveKeys(['key4', 'key5']);
      
      // Clean up
      await box.close();
    });
    
    // Test box creation helper
    test('Should create test box with sample data', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      final boxName = HiveTestHelpers.getUniqueBoxName('sample_data_box');
      final box = await HiveTestHelpers.createTestBox(
        boxName,
        testData: {
          'user1': {'name': 'John', 'age': 30},
          'user2': {'name': 'Jane', 'age': 25},
        },
      );
      
      // Verify the data
      final user1 = box.get('user1');
      final user2 = box.get('user2');
      
      expect(user1, isA<Map>());
      expect(user1?['name'], 'John');
      expect(user1?['age'], 30);
      
      expect(user2, isA<Map>());
      expect(user2?['name'], 'Jane');
      expect(user2?['age'], 25);
      
      // Clean up
      await box.close();
    });
    
    // Test with multiple operations
    test('Should handle complex operations', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      final boxName = HiveTestHelpers.getUniqueBoxName('complex_box');
      final box = await Hive.openBox<Map>(boxName);
      
      // Add data
      await box.put('item1', {'count': 1, 'tags': ['A', 'B']});
      
      // Update data
      final item = box.get('item1');
      if (item != null) {
        item['count'] = 2;
        item['tags'].add('C');
        await box.put('item1', item);
      }
      
      // Verify updates
      final updatedItem = box.get('item1');
      expect(updatedItem?['count'], 2);
      expect(updatedItem?['tags'], ['A', 'B', 'C']);
      
      // Delete data
      await box.delete('item1');
      expect(box.get('item1'), null);
      
      // Clean up
      await box.close();
    });
  });
  
  // Test group for box operations as they would be used in the app
  group('Hive Cache Integration', () {
    late Box<Map> cacheBox;
    
    setUp(() async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      // Initialize Hive for this test group if not already initialized
      await HiveTestHelpers.setUpHiveForTesting();
      
      // Create a fresh box for each test
      final boxName = HiveTestHelpers.getUniqueBoxName('cache_box');
      cacheBox = await Hive.openBox<Map>(boxName);
    });
    
    tearDown(() async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      // Close the box after each test
      await cacheBox.close();
    });
    
    test('Should store and retrieve cache entries', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      // Create a cache entry with TTL
      final cacheEntry = {
        'data': {'id': '123', 'name': 'Test Item'},
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'ttl': 3600000, // 1 hour in milliseconds
      };
      
      // Store in cache
      await cacheBox.put('cache:item:123', cacheEntry);
      
      // Retrieve from cache
      final retrievedEntry = cacheBox.get('cache:item:123');
      
      // Verify
      expect(retrievedEntry, isNotNull);
      expect(retrievedEntry?['data']?['id'], '123');
      expect(retrievedEntry?['data']?['name'], 'Test Item');
      expect(retrievedEntry?['ttl'], 3600000);
    });
    
    test('Should handle cache expiration logic', () async {
      // Skip if Hive tests are disabled
      if (HiveTestHelpers.shouldSkipHiveTests()) return;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      
      // Create expired cache entry
      final expiredEntry = {
        'data': {'id': 'expired'},
        'timestamp': now - 3600000, // 1 hour ago
        'ttl': 1800000, // 30 minutes
      };
      
      // Create valid cache entry
      final validEntry = {
        'data': {'id': 'valid'},
        'timestamp': now - 900000, // 15 minutes ago
        'ttl': 1800000, // 30 minutes
      };
      
      // Store in cache
      await cacheBox.put('cache:expired', expiredEntry);
      await cacheBox.put('cache:valid', validEntry);
      
      // Check expiration logic
      final isExpiredItemValid = _isCacheValid(cacheBox.get('cache:expired'));
      final isValidItemValid = _isCacheValid(cacheBox.get('cache:valid'));
      
      // Verify
      expect(isExpiredItemValid, false);
      expect(isValidItemValid, true);
    });
  });
}

// Helper function to check if a cache entry is valid
bool _isCacheValid(Map? entry) {
  if (entry == null) return false;
  
  final timestamp = entry['timestamp'] as int?;
  final ttl = entry['ttl'] as int?;
  
  if (timestamp == null || ttl == null) return false;
  
  final now = DateTime.now().millisecondsSinceEpoch;
  return now < timestamp + ttl;
} 