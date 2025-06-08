import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/core/cache/cache_manager.dart';
import 'package:hive_ui/core/cache/cache_providers.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';

/// A service that warms up the cache by preloading frequently accessed data
class CacheWarmer {
  final Ref _ref;
  final CacheManager _cacheManager;
  bool _isWarming = false;
  
  /// Constructor
  CacheWarmer(this._ref) : _cacheManager = _ref.read(cacheManagerProvider);
  
  /// Warm critical caches to improve user experience
  Future<void> warmCache() async {
    if (_isWarming) return;
    
    _isWarming = true;
    debugPrint('🔥 CacheWarmer: Starting cache warming...');
    
    try {
      // Get current user ID
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        debugPrint('🔥 CacheWarmer: No authenticated user, skipping user-specific warming');
        return;
      }
      
      // Warm up user profile data
      await _warmUserProfile(userId);
      
      debugPrint('🔥 CacheWarmer: Cache warming completed successfully');
    } catch (e) {
      debugPrint('🔥 CacheWarmer: Error during cache warming: $e');
    } finally {
      _isWarming = false;
    }
  }
  
  /// Clear all warmed caches
  Future<void> clearWarmedCaches() async {
    _cacheManager.clearCache();
    debugPrint('🔥 CacheWarmer: All warmed caches cleared');
  }
  
  /// Warm user profile data
  Future<void> _warmUserProfile(String userId) async {
    debugPrint('🔥 CacheWarmer: Warming user profile cache...');
    
    try {
      // Load the current user's profile
      final profile = await _ref.read(profileRepositoryProvider).getProfile(userId);
      if (profile != null) {
        _cacheManager.put(
          'user:$userId:profile', 
          profile,
        );
        
        // Also warm saved events
        final savedEvents = await _ref.read(profileRepositoryProvider).getSavedEvents(userId);
        _cacheManager.put(
          'user:$userId:savedEvents', 
          savedEvents,
        );
        
        // And joined spaces
        final joinedSpaces = await _ref.read(profileRepositoryProvider).getJoinedSpaces(userId);
        _cacheManager.put(
          'user:$userId:spaces', 
          joinedSpaces,
        );
        
        debugPrint('🔥 CacheWarmer: User profile cache warmed with ${savedEvents.length} saved events and ${joinedSpaces.length} spaces');
      }
    } catch (e) {
      debugPrint('🔥 CacheWarmer: Error warming user profile: $e');
    }
  }
}

/// Provider for accessing the cache warmer
final cacheWarmerProvider = Provider<CacheWarmer>((ref) {
  return CacheWarmer(ref);
});

/// Auto-warming provider that can be watched to trigger cache warming
final cacheWarmingProvider = FutureProvider<bool>((ref) async {
  final warmer = ref.watch(cacheWarmerProvider);
  await warmer.warmCache();
  return true;
}); 