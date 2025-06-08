import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/feed/domain/usecases/handle_interactions_use_case.dart';
import 'package:hive_ui/features/repost/domain/repositories/repost_repository.dart';
import 'package:hive_ui/models/event.dart';
import 'package:hive_ui/models/repost_content_type.dart';
import 'package:hive_ui/features/feed/domain/providers/feed_domain_providers.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';
import 'package:hive_ui/models/repost.dart';
import 'package:hive_ui/models/user_profile.dart';
import 'package:flutter/material.dart';

/// A temporary mock implementation of RepostRepository
class RepostRepositoryMock implements RepostRepository {
  @override
  Future<Repost> createRepost({
    required String userId,
    required String eventId,
    required Event event,
    String? text,
    required String contentType,
  }) async {
    // Convert string contentType to enum
    final contentTypeEnum = RepostContentType.values.firstWhere(
      (type) => type.name == contentType,
      orElse: () => RepostContentType.standard,
    );
    
    // Return a mock repost
    return Repost(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      eventId: eventId,
      text: text,
      createdAt: DateTime.now(),
      contentType: contentTypeEnum,
      originalEventTitle: event.title,
      originalEventImageUrl: event.imageUrl,
    );
  }
  
  @override
  Future<void> deleteRepost(String repostId) async {
    // No implementation needed for mock
  }
  
  @override
  Future<List<Repost>> getRepostsByUser(String userId) async {
    // Return empty list for mock
    return [];
  }
  
  @override
  Future<List<Repost>> getRepostsForEvent(String eventId) async {
    // Return empty list for mock
    return [];
  }
  
  @override
  Future<void> updateRepost(Repost repost) async {
    // No implementation needed for mock
  }
  
  // Mock method to add a repost
  Future<void> addRepost({
    required Event event,
    required UserProfile repostedBy,
    String? comment,
    required RepostContentType type,
  }) async {
    // Simply create a repost with the data provided
    final repost = createRepost(
      userId: repostedBy.id,
      eventId: event.id,
      event: event,
      text: comment,
      contentType: type.name,
    );
    
    debugPrint('Mock repost created: ${event.title} by ${repostedBy.displayName}');
  }
}

/// Provider for the repost repository
final repostRepositoryProvider = Provider<RepostRepository>((ref) {
  // Return mock implementation
  return RepostRepositoryMock();
});

/// Provider for the HandleInteractionsUseCase
final feedInteractionsProvider = Provider<HandleInteractionsUseCase>((ref) {
  final feedRepository = ref.watch(feedRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  final repostRepository = ref.watch(repostRepositoryProvider);
  
  return HandleInteractionsUseCase(
    feedRepository: feedRepository,
    profileRepository: profileRepository,
    repostRepository: repostRepository,
  );
});

/// Provider for handling RSVP state
final rsvpStateProvider = StateNotifierProvider<RsvpStateNotifier, Map<String, bool>>((ref) {
  return RsvpStateNotifier(ref);
});

/// Notifier for managing RSVP state
class RsvpStateNotifier extends StateNotifier<Map<String, bool>> {
  final Ref _ref;
  
  RsvpStateNotifier(this._ref) : super({});
  
  /// Toggle RSVP status for an event
  Future<bool> toggleRsvp(Event event) async {
    final eventId = event.id;
    
    // Get current RSVP status
    final isCurrentlyRsvped = state[eventId] ?? false;
    final newRsvpStatus = !isCurrentlyRsvped;
    
    // Optimistically update state
    state = {...state, eventId: newRsvpStatus};
    
    try {
      // Use the feed provider directly since the use case has compatibility issues
      await _ref.read(feedRepositoryProvider).rsvpToEvent(eventId, newRsvpStatus);
      return true;
    } catch (e) {
      // Revert state if failed
      state = {...state, eventId: isCurrentlyRsvped};
      return false;
    }
  }
  
  /// Set RSVP status for an event without calling backend
  void setRsvpStatus(String eventId, bool isRsvped) {
    state = {...state, eventId: isRsvped};
  }
  
  /// Clear all RSVP states
  void clear() {
    state = {};
  }
}

/// Provider for handling repost actions
final repostActionProvider = Provider((ref) {
  return RepostAction(ref);
});

/// Class for handling repost actions
class RepostAction {
  final Ref _ref;
  
  RepostAction(this._ref);
  
  /// Repost an event with optional comment
  Future<bool> repostEvent(Event event, String? comment, RepostContentType type) async {
    try {
      // Use the repost repository directly
      final repostRepo = _ref.read(repostRepositoryProvider) as RepostRepositoryMock;
      await repostRepo.addRepost(
        event: event,
        repostedBy: _ref.read(profileProvider).profile!,
        comment: comment,
        type: type,
      );
      return true;
    } catch (e) {
      debugPrint('Error reposting event: $e');
      return false;
    }
  }
} 