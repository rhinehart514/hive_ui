import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/core/cache/cache_warmer.dart';
import 'package:hive_ui/core/cache/hive_initialize.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';
import 'package:hive_ui/core/network/connectivity_service.dart';
import 'package:hive_ui/core/network/offline_queue_manager.dart';
import 'package:hive_ui/core/refresh/global_refresh_controller.dart';
import 'package:hive_ui/core/security/sensitive_data_encryption.dart';
import 'dart:async';

/// Initializes core application components
class AppInitializer {
  static bool _isInitialized = false;
  
  /// Initialize all required components
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🚀 AppInitializer: Starting initialization...');
    
    // Initialize components
    _initializeEventBus();
    _initializeCacheManager();
    _initializeConnectivityService();
    await _initializeEncryptionService();
    await _initializeHive();
    
    _isInitialized = true;
    debugPrint('✅ AppInitializer: Initialization complete!');
  }
  
  /// Initialize the event bus
  static void _initializeEventBus() {
    // Just access it to trigger initialization
    final eventBus = AppEventBus();
    debugPrint('📡 AppInitializer: Event bus initialized');
  }
  
  /// Initialize the cache manager
  static void _initializeCacheManager() {
    // Just access it to trigger initialization
    final cacheManager = CacheManager();
    debugPrint('💾 AppInitializer: Cache manager initialized');
  }
  
  /// Initialize the connectivity service
  static void _initializeConnectivityService() {
    // This will be fully initialized when accessed through the provider
    debugPrint('🔌 AppInitializer: Connectivity service ready');
  }
  
  /// Initialize the encryption service
  static Future<void> _initializeEncryptionService() async {
    try {
      // Add timeout for encryption service initialization
      final timeout = const Duration(seconds: 3);
      final encryptionService = SensitiveDataEncryption();
      
      await encryptionService.initialize().timeout(timeout, onTimeout: () {
        debugPrint('⏱️ AppInitializer: Encryption service initialization timed out');
        return;
      });
      
      debugPrint('🔒 AppInitializer: Encryption service initialized');
    } catch (e) {
      debugPrint('❌ AppInitializer: Encryption initialization failed: $e');
      // Continue without encryption in case of failure
    }
  }
  
  /// Initialize Hive database
  static Future<void> _initializeHive() async {
    try {
      // Add timeout for Hive initialization
      final timeout = const Duration(seconds: 3);
      
      await HiveInitialize.init().timeout(timeout, onTimeout: () {
        debugPrint('⏱️ AppInitializer: Hive initialization timed out');
        throw TimeoutException('Hive initialization timed out');
      });
      
      debugPrint('🐝 AppInitializer: Hive database initialized');
    } catch (e) {
      debugPrint('❌ AppInitializer: Failed to initialize Hive: $e');
      // Continue without Hive in case of failure
    }
  }
  
  /// Initialize Riverpod providers that need to be accessed at startup
  static void initializeProviders(Ref ref) {
    // Initialize the global refresh controller
    final refreshController = ref.read(globalRefreshControllerProvider);
    debugPrint('🔄 AppInitializer: Global refresh controller initialized');
    
    // Initialize connectivity service
    final connectivityService = ref.read(connectivityServiceProvider);
    debugPrint('🔌 AppInitializer: Connectivity service initialized');
    
    // Initialize offline queue manager
    final offlineQueueManager = ref.read(offlineQueueManagerProvider);
    debugPrint('⏱️ AppInitializer: Offline queue manager initialized');
    
    // Initialize and start cache warming
    _initializeCacheWarming(ref);
  }
  
  /// Initialize cache warming
  static Future<void> _initializeCacheWarming(Ref ref) async {
    debugPrint('🔥 AppInitializer: Starting cache warmer...');
    
    // Wait a short time to allow the app to finish startup
    // This prevents blocking the UI during initial load
    await Future.delayed(const Duration(seconds: 2));
    
    // Start cache warming
    final cacheWarmer = ref.read(cacheWarmerProvider);
    cacheWarmer.warmCache().then((_) {
      debugPrint('🔥 AppInitializer: Initial cache warming completed');
    });
  }
  
  /// Log cache statistics for debugging
  static void logCacheStats(Ref ref) {
    final cacheManager = ref.read(cacheManagerProvider);
    cacheManager.logStats();
  }
  
  /// Log offline queue statistics for debugging
  static void logOfflineQueueStats(Ref ref) {
    final offlineQueueManager = ref.read(offlineQueueManagerProvider);
    final pendingActions = offlineQueueManager.pendingActions;
    debugPrint('⏱️ OfflineQueueStats: ${pendingActions.length} pending actions');
    
    // Log by resource type
    final resourceTypes = <String, int>{};
    for (final action in pendingActions) {
      resourceTypes[action.resourceType] = (resourceTypes[action.resourceType] ?? 0) + 1;
    }
    
    for (final entry in resourceTypes.entries) {
      debugPrint('⏱️ OfflineQueueStats: ${entry.value} pending actions for ${entry.key}');
    }
  }
}

/// Provider to trigger app initialization
final appInitializerProvider = Provider<bool>((ref) {
  // Initialize providers that require Ref
  AppInitializer.initializeProviders(ref);
  return true;
});

/// Provider for logging cache statistics (can be watched to trigger stats)
final cacheStatsLoggingProvider = Provider<Function>((ref) {
  return () => AppInitializer.logCacheStats(ref);
});

/// Provider for logging offline queue statistics
final offlineQueueStatsLoggingProvider = Provider<Function>((ref) {
  return () => AppInitializer.logOfflineQueueStats(ref);
});

/// Provider for the encryption service
final encryptionServiceProvider = Provider<SensitiveDataEncryption>((ref) {
  return SensitiveDataEncryption();
}); 