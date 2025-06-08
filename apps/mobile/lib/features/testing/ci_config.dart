import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

/// Configuration for Continuous Integration testing
///
/// This class centralizes CI environment settings, test categories,
/// and helper methods for running tests in CI environments
class CIConfig {
  /// Whether we're currently running in a CI environment
  static bool get isInCIEnvironment {
    // Check standard CI environment variables
    return Platform.environment.containsKey('CI') ||
           Platform.environment.containsKey('CONTINUOUS_INTEGRATION') ||
           Platform.environment.containsKey('GITHUB_ACTIONS') ||
           Platform.environment.containsKey('CIRCLECI') ||
           Platform.environment.containsKey('TRAVIS') ||
           Platform.environment.containsKey('APPVEYOR') ||
           Platform.environment.containsKey('GITLAB_CI');
  }
  
  /// Categories of tests that can be run
  static const Map<String, TestCategory> testCategories = {
    'all': TestCategory.all,
    'unit': TestCategory.unit,
    'widget': TestCategory.widget,
    'integration': TestCategory.integration,
    'golden': TestCategory.golden,
    'performance': TestCategory.performance,
  };
  
  /// Get test categories to run based on environment variables or config
  static Set<TestCategory> getTestCategories() {
    const categoryStr = String.fromEnvironment('TEST_CATEGORIES', defaultValue: 'unit,widget');
    final categoryList = categoryStr.split(',').map((e) => e.trim().toLowerCase()).toList();
    
    final categories = <TestCategory>{};
    for (final category in categoryList) {
      if (testCategories.containsKey(category)) {
        categories.add(testCategories[category]!);
      }
    }
    
    // Default to unit tests if no valid categories specified
    if (categories.isEmpty) {
      categories.add(TestCategory.unit);
    }
    
    return categories;
  }
  
  /// Generate test tags based on categories
  static List<String> getTestTags() {
    final categories = getTestCategories();
    final tags = <String>[];
    
    for (final category in categories) {
      switch (category) {
        case TestCategory.unit:
          tags.add('unit');
          break;
        case TestCategory.widget:
          tags.add('widget');
          break;
        case TestCategory.integration:
          tags.add('integration');
          break;
        case TestCategory.golden:
          tags.add('golden');
          break;
        case TestCategory.performance:
          tags.add('performance');
          break;
        case TestCategory.all:
          return []; // Empty tags means run all tests
      }
    }
    
    return tags;
  }
  
  /// Check if mock database should be used (always true in CI, configurable in dev)
  static bool get useMockDatabase {
    if (isInCIEnvironment) return true;
    return const bool.fromEnvironment('USE_MOCK_DB', defaultValue: true);
  }
  
  /// Timeout duration for tests in CI vs development
  static Duration get testTimeout {
    if (isInCIEnvironment) {
      return const Duration(minutes: 5); // Stricter timeout in CI
    }
    return const Duration(minutes: 10); // More flexible for local development
  }
  
  /// Whether to include Hive database tests
  static bool get includeHiveTests {
    return const bool.fromEnvironment('INCLUDE_HIVE_TESTS', defaultValue: true);
  }
  
  /// Log CI test configuration
  static void logTestConfig() {
    final categories = getTestCategories();
    final categoryNames = categories.map((e) => e.toString().split('.').last).join(', ');
    
    debugPrint('🧪 CI Test Configuration:');
    debugPrint('🧪 Running in CI Environment: $isInCIEnvironment');
    debugPrint('🧪 Test Categories: $categoryNames');
    debugPrint('🧪 Using Mock Database: $useMockDatabase');
    debugPrint('🧪 Include Hive Tests: $includeHiveTests');
    debugPrint('🧪 Test Timeout: ${testTimeout.inMinutes} minutes');
  }
}

/// Categories of tests that can be run
enum TestCategory {
  /// All test types
  all,
  
  /// Unit tests for business logic
  unit,
  
  /// Widget tests for UI components
  widget,
  
  /// Integration tests for full features
  integration,
  
  /// Golden tests for UI appearance
  golden,
  
  /// Performance tests
  performance,
} 