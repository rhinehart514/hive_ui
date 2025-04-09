import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/providers/feed_domain_providers.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/providers/event_providers.dart';
import 'package:hive_ui/features/spaces/presentation/providers/space_providers.dart';
import 'package:hive_ui/core/event_bus/app_event_bus.dart';

/// Defines targets for refresh operations
enum RefreshTarget {
  feed,
  events,
  profile,
  spaces,
  all,
}

/// A controller that handles refresh operations across the app
class GlobalRefreshController extends ChangeNotifier {
  final Ref _ref;
  bool _isRefreshing = false;
  
  /// Get current refreshing state
  bool get isRefreshing => _isRefreshing;
  
  /// Constructor
  GlobalRefreshController(this._ref);
  
  /// Request a refresh of specific app components
  Future<void> requestRefresh(RefreshTarget target, {bool notify = true}) async {
    if (_isRefreshing) {
      debugPrint('🔄 GlobalRefreshController: Already refreshing, skipping request');
      return;
    }
    
    _isRefreshing = true;
    if (notify) notifyListeners();
    
    debugPrint('🔄 GlobalRefreshController: Refreshing $target');
    
    try {
      switch (target) {
        case RefreshTarget.feed:
          await _refreshFeed();
          break;
        case RefreshTarget.events:
          await _refreshEvents();
          break;
        case RefreshTarget.profile:
          await _refreshProfile();
          break;
        case RefreshTarget.spaces:
          await _refreshSpaces();
          break;
        case RefreshTarget.all:
          await _refreshAll();
          break;
      }
      
      // Emit a global refresh event
      AppEventBus().emit(GlobalRefreshEvent(target: target));
      
      debugPrint('✅ GlobalRefreshController: Successfully refreshed $target');
    } catch (e) {
      debugPrint('❌ GlobalRefreshController: Error refreshing $target: $e');
    } finally {
      _isRefreshing = false;
      if (notify) notifyListeners();
    }
  }
  
  /// Refresh feed
  Future<void> _refreshFeed() async {
    _ref.invalidate(feedStreamProvider);
  }
  
  /// Refresh events
  Future<void> _refreshEvents() async {
    // Invalidate relevant providers
    _ref.invalidate(eventsProvider);
    _ref.invalidate(refreshEventsProvider);
  }
  
  /// Refresh profile
  Future<void> _refreshProfile() async {
    await _ref.read(profileProvider.notifier).refreshProfile();
  }
  
  /// Refresh spaces
  Future<void> _refreshSpaces() async {
    // Invalidate spaces provider
    _ref.invalidate(spacesProvider);
  }
  
  /// Refresh all components
  Future<void> _refreshAll() async {
    _ref.invalidate(feedStreamProvider);
    
    await Future.wait([
      _refreshEvents(),
      _refreshProfile(),
      _refreshSpaces(),
    ]);
  }
}

/// Global refresh event
class GlobalRefreshEvent extends AppEvent {
  final RefreshTarget target;
  
  const GlobalRefreshEvent({required this.target});
}

/// Provider for the GlobalRefreshController
final globalRefreshControllerProvider = Provider<GlobalRefreshController>((ref) {
  return GlobalRefreshController(ref);
});

/// Provider to check if a refresh is in progress
final isRefreshingProvider = Provider<bool>((ref) {
  return ref.watch(globalRefreshControllerProvider).isRefreshing;
}); 