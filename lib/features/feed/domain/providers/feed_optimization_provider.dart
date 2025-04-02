import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../models/event.dart';
import '../../../../models/user_profile.dart';
import '../../../../models/repost_content_type.dart';
import '../../../../models/feed_state.dart';
import '../../../../providers/feed_provider.dart';
import '../../../../providers/profile_provider.dart';

/// State class for feed optimization
class FeedOptimizationState {
  /// Flag for tracking loading more events
  final bool isLoadingMore;
  
  /// Last time loadMore was called (for debouncing)
  final DateTime? lastLoadMoreTime;
  
  /// Map of optimistic RSVP statuses by event ID
  final Map<String, bool> optimisticRsvpStatuses;
  
  /// Map of optimistic repost status by event ID
  final Map<String, Map<String, dynamic>> optimisticReposts;
  
  /// Flag for tracking initial loading state
  final bool isInitialLoading;
  
  /// Error message if any
  final String? errorMessage;
  
  /// Constructor
  const FeedOptimizationState({
    this.isLoadingMore = false,
    this.lastLoadMoreTime,
    this.optimisticRsvpStatuses = const {},
    this.optimisticReposts = const {},
    this.isInitialLoading = false,
    this.errorMessage,
  });
  
  /// Create a copy with updated values
  FeedOptimizationState copyWith({
    bool? isLoadingMore,
    DateTime? lastLoadMoreTime,
    Map<String, bool>? optimisticRsvpStatuses,
    Map<String, Map<String, dynamic>>? optimisticReposts,
    bool? isInitialLoading,
    String? errorMessage,
  }) {
    return FeedOptimizationState(
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      lastLoadMoreTime: lastLoadMoreTime ?? this.lastLoadMoreTime,
      optimisticRsvpStatuses: optimisticRsvpStatuses ?? this.optimisticRsvpStatuses,
      optimisticReposts: optimisticReposts ?? this.optimisticReposts,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider for optimization state
final feedOptimizationProvider = StateNotifierProvider<FeedOptimizationNotifier, FeedOptimizationState>((ref) {
  return FeedOptimizationNotifier(ref);
});

/// Notifier for optimization state
class FeedOptimizationNotifier extends StateNotifier<FeedOptimizationState> {
  final Ref _ref;
  
  /// Debounce duration for load more
  static const Duration _debounceTime = Duration(milliseconds: 500);
  
  /// Constructor
  FeedOptimizationNotifier(this._ref) : super(const FeedOptimizationState());
  
  /// Set loading more state
  void setLoadingMore(bool isLoading) {
    state = state.copyWith(
      isLoadingMore: isLoading,
      lastLoadMoreTime: isLoading ? DateTime.now() : state.lastLoadMoreTime,
    );
  }
  
  /// Check if we can load more (debounced)
  bool canLoadMore() {
    // If already loading, don't load more
    if (state.isLoadingMore) return false;
    
    // If never loaded or enough time has passed, allow loading
    if (state.lastLoadMoreTime == null) return true;
    
    final now = DateTime.now();
    return now.difference(state.lastLoadMoreTime!) > _debounceTime;
  }
  
  /// Set optimistic RSVP status
  void setOptimisticRsvpStatus(String eventId, bool status) {
    final updatedStatuses = Map<String, bool>.from(state.optimisticRsvpStatuses);
    updatedStatuses[eventId] = status;
    
    state = state.copyWith(optimisticRsvpStatuses: updatedStatuses);
    
    // Also update the feed items locally for immediate UI feedback
    _updateFeedItemRsvpStatus(eventId, status);
  }
  
  /// Clear optimistic RSVP status
  void clearOptimisticRsvpStatus(String eventId) {
    final updatedStatuses = Map<String, bool>.from(state.optimisticRsvpStatuses);
    updatedStatuses.remove(eventId);
    
    state = state.copyWith(optimisticRsvpStatuses: updatedStatuses);
  }
  
  /// Add an optimistic repost to the local state
  void addOptimisticRepost(Event event, UserProfile profile, String? comment, RepostContentType type) {
    // Create a unique temporary ID for this optimistic repost
    final tempId = 'optimistic_${event.id}_${DateTime.now().millisecondsSinceEpoch}';
    
    // Store the optimistic repost
    final updatedReposts = Map<String, Map<String, dynamic>>.from(state.optimisticReposts);
    updatedReposts[event.id] = {
      'tempId': tempId,
      'event': event,
      'profile': profile,
      'comment': comment,
      'type': type,
      'timestamp': DateTime.now(),
      'status': 'pending', // Can be 'pending', 'confirmed', or 'failed'
    };
    
    state = state.copyWith(optimisticReposts: updatedReposts);
    
    // Add the optimistic repost to the feed items for immediate UI feedback
    _addOptimisticRepostToFeed(event, profile, comment, type, tempId);
  }
  
  /// Confirm an optimistic repost after it's been saved
  void confirmOptimisticRepost(String eventId) {
    if (!state.optimisticReposts.containsKey(eventId)) return;
    
    final updatedReposts = Map<String, Map<String, dynamic>>.from(state.optimisticReposts);
    final repost = updatedReposts[eventId]!;
    repost['status'] = 'confirmed';
    
    state = state.copyWith(optimisticReposts: updatedReposts);
  }
  
  /// Remove an optimistic repost if it failed or was cancelled
  void removeOptimisticRepost(String eventId) {
    final updatedReposts = Map<String, Map<String, dynamic>>.from(state.optimisticReposts);
    final repost = updatedReposts[eventId];
    
    if (repost != null) {
      final tempId = repost['tempId'] as String;
      
      // Remove the optimistic repost from the feed
      _removeOptimisticRepostFromFeed(tempId);
      
      // Remove from optimistic state
      updatedReposts.remove(eventId);
      state = state.copyWith(optimisticReposts: updatedReposts);
    }
  }
  
  /// Helper method to update RSVP status in feed items
  void _updateFeedItemRsvpStatus(String eventId, bool status) {
    final feedState = _ref.read(feedStateProvider);
    final currentUser = FirebaseAuth.instance.currentUser;
    final userId = currentUser?.uid ?? '';
    
    if (userId.isEmpty) {
      debugPrint('Cannot update RSVP status: No user ID available');
      return;
    }
    
    // Create a new list with the updated items
    final List<Event> updatedEvents = [];
    
    // Copy each event, modifying the one that matches the event ID
    for (final event in feedState.events) {
      if (event.id == eventId) {
        // Create a copy of the event with updated attendees list to reflect RSVP status
        List<String> updatedAttendees = List<String>.from(event.attendees);
        
        if (status && !updatedAttendees.contains(userId)) {
          // Add user to attendees
          updatedAttendees.add(userId);
        } else if (!status && updatedAttendees.contains(userId)) {
          // Remove user from attendees
          updatedAttendees.remove(userId);
        }
        
        // Create updated event with modified attendees list
        final updatedEvent = event.copyWith(
          attendees: updatedAttendees,
        );
        
        updatedEvents.add(updatedEvent);
      } else {
        // Add the unchanged event
        updatedEvents.add(event);
      }
    }
    
    // Update the feed state with the new list
    _ref.read(feedStateProvider.notifier).state = feedState.copyWith(
      events: updatedEvents,
    );
  }
  
  /// Helper method to add an optimistic repost to the feed
  void _addOptimisticRepostToFeed(
    Event event, 
    UserProfile profile, 
    String? comment, 
    RepostContentType type,
    String tempId,
  ) {
    final feedState = _ref.read(feedStateProvider);
    
    // Create the repost item using correct fields
    final repostItem = RepostItem(
      event: event,
      reposterProfile: profile,
      comment: comment,
      repostTime: DateTime.now(),
      contentType: type,
    );
    
    // Update the reposts list
    final updatedReposts = [repostItem, ...feedState.reposts];
    
    // Update the feed state - the FeedNotifier will handle combining items
    _ref.read(feedStateProvider.notifier).state = feedState.copyWith(
      reposts: updatedReposts,
    );
  }
  
  /// Helper method to remove an optimistic repost from the feed
  void _removeOptimisticRepostFromFeed(String tempId) {
    final feedState = _ref.read(feedStateProvider);
    
    if (feedState.reposts.isNotEmpty) {
      // Remove the most recent repost (assuming it's the optimistic one)
      final updatedReposts = feedState.reposts.skip(1).toList();
      
      // Update the feed state
      _ref.read(feedStateProvider.notifier).state = feedState.copyWith(
        reposts: updatedReposts,
      );
    }
  }
  
  /// Set initial loading state
  void setInitialLoading(bool isLoading) {
    state = state.copyWith(isInitialLoading: isLoading);
  }
  
  /// Set error message
  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }
  
  /// Update event RSVP status
  void updateEventRsvpStatus(String eventId, bool isRsvpd) {
    setOptimisticRsvpStatus(eventId, isRsvpd);
  }
  
  /// Add a repost to an event
  void addRepost(String eventId) {
    final feedState = _ref.read(feedStateProvider);
    
    // Find the event in the feed
    Event? event;
    UserProfile? currentUserProfile;
    
    // Search through the events list to find the matching event
    for (final e in feedState.events) {
      if (e.id == eventId) {
        event = e;
        break;
      }
    }
    
    if (event != null) {
      // Get current user profile from the profile provider
      try {
        currentUserProfile = _ref.read(profileProvider).profile;
        
        if (currentUserProfile != null) {
          // Add optimistic repost to feed
          addOptimisticRepost(
            event,
            currentUserProfile,
            null, // No comment
            RepostContentType.standard,
          );
        }
      } catch (e) {
        debugPrint('Error getting user profile: $e');
      }
    }
  }
  
  /// Remove a repost from an event
  void removeRepost(String eventId) {
    removeOptimisticRepost(eventId);
  }
} 