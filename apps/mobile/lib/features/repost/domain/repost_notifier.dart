import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/event.dart';
import '../../../models/repost.dart';
import '../../../models/repost_content_type.dart';
import '../data/repositories/repost_repository.dart';
import 'repost_state.dart';

class RepostNotifier extends StateNotifier<RepostState> {
  final RepostRepository _repository;

  RepostNotifier({required RepostRepository repository})
      : _repository = repository,
        super(const RepostState());

  // Create a new repost
  Future<void> createRepost({
    required String userId,
    required String eventId,
    required Event event,
    String? text,
    RepostContentType contentType = RepostContentType.standard,
  }) async {
    state = state.setSubmitting(true);

    try {
      final repost = await _repository.createRepost(
        userId: userId,
        eventId: eventId,
        event: event,
        text: text,
        contentType: contentType.name,
      );

      // Update user reposts list
      final updatedUserReposts = [repost, ...state.userReposts];
      
      // Update event reposts list if we're viewing that event
      List<Repost> updatedEventReposts = state.eventReposts;
      if (state.eventReposts.any((r) => r.eventId == eventId)) {
        updatedEventReposts = [repost, ...state.eventReposts];
      }
      
      // Update feed reposts
      final updatedFeedReposts = [repost, ...state.feedReposts];

      state = state.copyWith(
        userReposts: updatedUserReposts,
        eventReposts: updatedEventReposts,
        feedReposts: updatedFeedReposts,
        isSubmitting: false,
        status: RepostStatus.success,
      );
    } catch (e) {
      state = state.setError(e.toString());
    }
  }

  // Load reposts for a specific user
  Future<void> loadUserReposts(String userId) async {
    state = state.setLoading();

    try {
      final reposts = await _repository.getRepostsByUser(userId);
      state = state.copyWith(
        userReposts: reposts,
        status: RepostStatus.success,
      );
    } catch (e) {
      state = state.setError('Failed to load user reposts: ${e.toString()}');
    }
  }

  // Load reposts for a specific event
  Future<void> loadEventReposts(String eventId) async {
    state = state.setLoading();

    try {
      final reposts = await _repository.getRepostsForEvent(eventId);
      state = state.copyWith(
        eventReposts: reposts,
        status: RepostStatus.success,
      );
    } catch (e) {
      state = state.setError('Failed to load event reposts: ${e.toString()}');
    }
  }

  // Delete a repost
  Future<void> deleteRepost(Repost repost) async {
    state = state.setSubmitting(true);

    try {
      await _repository.deleteRepost(repost.id);

      // Update user reposts list
      final updatedUserReposts = state.userReposts
          .where((r) => r.id != repost.id)
          .toList();
      
      // Update event reposts list
      final updatedEventReposts = state.eventReposts
          .where((r) => r.id != repost.id)
          .toList();
      
      // Update feed reposts
      final updatedFeedReposts = state.feedReposts
          .where((r) => r.id != repost.id)
          .toList();

      state = state.copyWith(
        userReposts: updatedUserReposts,
        eventReposts: updatedEventReposts,
        feedReposts: updatedFeedReposts,
        isSubmitting: false,
        status: RepostStatus.success,
      );
    } catch (e) {
      state = state.setError('Failed to delete repost: ${e.toString()}');
    }
  }

  // Like or unlike a repost
  Future<void> toggleLike(String repostId, String userId) async {
    try {
      await _repository.likeRepost(repostId, userId);
      
      // Update UI optimistically - toggle like status in all lists
      final updatedUserReposts = _toggleLikeInList(state.userReposts, repostId, userId);
      final updatedEventReposts = _toggleLikeInList(state.eventReposts, repostId, userId);
      final updatedFeedReposts = _toggleLikeInList(state.feedReposts, repostId, userId);
      
      state = state.copyWith(
        userReposts: updatedUserReposts,
        eventReposts: updatedEventReposts,
        feedReposts: updatedFeedReposts,
      );
    } catch (e) {
      state = state.setError('Failed to like repost: ${e.toString()}');
    }
  }
  
  // Helper method to toggle like status in a list of reposts
  List<Repost> _toggleLikeInList(List<Repost> reposts, String repostId, String userId) {
    return reposts.map((repost) {
      if (repost.id == repostId) {
        final isLiked = repost.likedBy.contains(userId);
        final updatedLikedBy = isLiked
            ? repost.likedBy.where((id) => id != userId).toList()
            : [...repost.likedBy, userId];
        
        return repost.copyWith(
          likedBy: updatedLikedBy,
          likeCount: isLiked ? repost.likeCount - 1 : repost.likeCount + 1,
        );
      }
      return repost;
    }).toList();
  }
  
  // Listen to feed reposts stream
  void listenToFeedReposts(List<String> followedUserIds) {
    _repository.streamUserFeedReposts(followedUserIds).listen(
      (reposts) {
        state = state.copyWith(
          feedReposts: reposts,
          status: RepostStatus.success,
        );
      },
      onError: (error) {
        state = state.setError('Error loading feed reposts: $error');
      },
    );
  }
  
  // Quote repost an event
  Future<void> createQuoteRepost({
    required String userId,
    required String eventId,
    required Event event,
    required String quoteText,
  }) async {
    return createRepost(
      userId: userId,
      eventId: eventId,
      event: event,
      text: quoteText,
      contentType: RepostContentType.quote,
    );
  }
  
  // Clear error
  void clearError() {
    state = state.clearError();
  }
} 