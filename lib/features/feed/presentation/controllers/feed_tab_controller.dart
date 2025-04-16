import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:hive_ui/features/feed/presentation/providers/feed_interaction_provider.dart' as old_providers;
import 'package:hive_ui/features/feed/presentation/providers/rsvp_provider.dart';
import 'package:hive_ui/features/feed/domain/providers/feed_domain_providers.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';

/// Controller provider for Feed Tab
final feedTabControllerProvider = Provider((ref) {
  return FeedTabController(ref);
});

/// A controller that combines all feed tab functionality
class FeedTabController {
  final Ref _ref;
  
  /// Constructor
  FeedTabController(this._ref);
  
  /// Handle RSVP action for an event
  Future<bool> handleRsvp(Event event) async {
    HapticFeedback.lightImpact(); // Light initial feedback
    return _ref.read(rsvpStateProvider.notifier).toggleRsvp(event);
  }
  
  /// Check if user is RSVP'd to an event
  bool isRsvpedToEvent(String eventId) {
    return _ref.read(rsvpStateProvider)[eventId] ?? false;
  }
  
  /// Check if RSVP is in loading state
  bool isRsvpLoading(String eventId) {
    return _ref.read(rsvpLoadingProvider.notifier).isLoading(eventId);
  }
  
  /// Load RSVP status for an event
  Future<void> loadRsvpStatus(String eventId) async {
    await _ref.read(rsvpStateProvider.notifier).loadRsvpStatus(eventId);
  }
  
  /// Load RSVP statuses for multiple events
  Future<void> loadRsvpStatuses(List<Event> events) async {
    await _ref.read(rsvpStateProvider.notifier).loadRsvpStatuses(events);
  }
  
  /// Handle repost action
  Future<bool> handleRepost(
    Event event, 
    String? comment, 
    RepostContentType type
  ) async {
    HapticFeedback.mediumImpact();
    return _ref.read(old_providers.repostActionProvider).repostEvent(event, comment, type);
  }
  
  /// Refresh feed content
  Future<void> refreshFeed() async {
    // Use the stream provider's future to refresh the feed
    await _ref.refresh(feedStreamProvider.future);
    debugPrint('Feed refreshed successfully');
  }
  
  /// Load more feed content - simplified version
  Future<void> loadMoreFeed() async {
    // This is a simplified version as the actual implementation would 
    // depend on the pagination mechanism used in your app
    debugPrint('Loading more feed content...');
    
    // In a real implementation, this would:
    // 1. Check if more content is available
    // 2. Increment the page number
    // 3. Fetch the next page of content
    // 4. Append it to the existing feed
    
    // For now, we'll just provide a placeholder implementation
    await Future.delayed(const Duration(milliseconds: 300));
    debugPrint('More feed content loaded');
  }
  
  /// Navigate to event details
  void navigateToEventDetails(BuildContext context, Event event) {
    // Implementation depends on navigation system, typically:
    // Navigator.of(context).push(MaterialPageRoute(
    //   builder: (context) => EventDetailsPage(event: event),
    // ));
  }
  
  /// Handle report action
  Future<void> reportEvent(Event event) async {
    // Implementation depends on reporting system
  }
} 