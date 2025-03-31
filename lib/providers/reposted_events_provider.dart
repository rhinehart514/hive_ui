import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reposted_event.dart';
import '../models/event.dart';
import '../models/user_profile.dart';
import '../models/repost_content_type.dart';

/// Provider for storing and retrieving reposted events
final repostedEventsProvider = StateNotifierProvider<RepostedEventsNotifier, List<RepostedEvent>>((ref) {
  return RepostedEventsNotifier();
});

/// Notifier class for reposted events
class RepostedEventsNotifier extends StateNotifier<List<RepostedEvent>> {
  RepostedEventsNotifier() : super([]);
  
  /// Add a reposted event
  void addRepost({
    required Event event,
    required UserProfile repostedBy,
    String? comment,
    required RepostContentType type,
  }) {
    // For quote reposts, ensure we have a comment
    if (type == RepostContentType.quote && (comment == null || comment.trim().isEmpty)) {
      print('Warning: Quote repost requires comment text');
      return; // Don't create a quote repost without comment text
    }
    
    // Create a new reposted event
    final repost = RepostedEvent.create(
      event: event,
      repostedBy: repostedBy,
      comment: comment,
      repostType: type.name,
    );
    
    // Add to the state
    state = [...state, repost];
    
    // For debugging
    print('Created repost: ${type.name} with comment: $comment');
    
    // In a real app, would save to the backend here
    _saveRepostToBackend(repost);
  }
  
  /// Get all reposted events
  List<RepostedEvent> getAllReposts() {
    return state;
  }
  
  /// Get reposted events by the current user
  List<RepostedEvent> getRepostsByUser(String userId) {
    return state.where((repost) => repost.repostedBy.id == userId).toList();
  }
  
  /// Check if an event has been reposted by a user
  bool isEventRepostedBy(String eventId, String userId) {
    return state.any((repost) => 
      repost.event.id == eventId && 
      repost.repostedBy.id == userId
    );
  }
  
  /// Get all events that should be shown in the feed, including reposted events
  List<Event> getEventsForFeed(List<Event> originalEvents) {
    // In a real implementation, we would merge original events with reposted events
    // and sort by timestamp
    return originalEvents;
  }
  
  /// Mock method to save repost to backend
  void _saveRepostToBackend(RepostedEvent repost) {
    // In a real app, this would make an API call to save the repost
    // For now, we'll just simulate it
    print('Reposted event: ${repost.event.title} by ${repost.repostedBy.displayName}');
  }
} 