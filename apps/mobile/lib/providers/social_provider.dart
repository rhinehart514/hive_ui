import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/providers/profile_provider.dart';

/// States for social interactions (follow, unfollow)
enum SocialActionState {
  /// No action in progress
  idle,

  /// Action is currently in progress
  loading,

  /// Action completed successfully
  success,

  /// Action failed with an error
  error
}

/// Provider for social interactions like following/unfollowing users
class SocialNotifier extends StateNotifier<AsyncValue<Map<String, bool>>> {
  /// Access to other providers
  final Ref _ref;

  SocialNotifier(this._ref) : super(const AsyncValue.data({}));

  /// Check if the current user is following another user
  bool isFollowing(String userId) {
    return state.valueOrNull?[userId] ?? false;
  }

  /// Follow a user
  Future<void> followUser(String userId) async {
    try {
      // Get current following state
      final currentState = Map<String, bool>.from(state.valueOrNull ?? {});

      // Update local state immediately for responsiveness
      currentState[userId] = true;
      state = AsyncValue.data(currentState);

      // Call API to follow user
      await _performFollowAction(userId, true);

      // Update the user profile to reflect new follower count
      _updateFollowerCounts(userId, increment: true);
    } catch (error, stackTrace) {
      // Revert state on error
      final currentState = Map<String, bool>.from(state.valueOrNull ?? {});
      currentState.remove(userId);
      state = AsyncValue.error(error, stackTrace);

      // Re-throw to allow UI to handle
      rethrow;
    }
  }

  /// Unfollow a user
  Future<void> unfollowUser(String userId) async {
    try {
      // Get current following state
      final currentState = Map<String, bool>.from(state.valueOrNull ?? {});

      // Update local state immediately for responsiveness
      currentState[userId] = false;
      state = AsyncValue.data(currentState);

      // Call API to unfollow user
      await _performFollowAction(userId, false);

      // Update the user profile to reflect new follower count
      _updateFollowerCounts(userId, increment: false);
    } catch (error, stackTrace) {
      // Revert state on error
      final currentState = Map<String, bool>.from(state.valueOrNull ?? {});
      currentState[userId] = true;
      state = AsyncValue.error(error, stackTrace);

      // Re-throw to allow UI to handle
      rethrow;
    }
  }

  /// Toggle follow status
  Future<void> toggleFollow(String userId) async {
    final isCurrentlyFollowing = isFollowing(userId);

    if (isCurrentlyFollowing) {
      await unfollowUser(userId);
    } else {
      await followUser(userId);
    }
  }

  /// Initialize following status for a user
  Future<void> initializeFollowingStatus(String userId) async {
    try {
      // Simulate API call to get following status
      await Future.delayed(const Duration(milliseconds: 300));

      // Mock response - in a real app this would be from the API
      const isFollowing = false;

      // Update state
      final currentState = Map<String, bool>.from(state.valueOrNull ?? {});
      currentState[userId] = isFollowing;
      state = AsyncValue.data(currentState);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Fetch users that the current user is following
  Future<List<String>> fetchFollowing() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock response - in a real app this would be from the API
      return [];
    } catch (error) {
      debugPrint('Error fetching following: $error');
      return [];
    }
  }

  /// Fetch users who follow the current user
  Future<List<String>> fetchFollowers() async {
    try {
      // Simulate API call
      await Future.delayed(const Duration(milliseconds: 500));

      // Mock response - in a real app this would be from the API
      return [];
    } catch (error) {
      debugPrint('Error fetching followers: $error');
      return [];
    }
  }

  /// Private method to update user profile follower counts
  void _updateFollowerCounts(String userId, {required bool increment}) {
    try {
      // Get the profile of the user being followed/unfollowed
      final userProfile = _ref.read(profileProvider).value;

      // If we have the profile and it matches the userId, update it
      if (userProfile != null && userProfile.id == userId) {
        final updatedProfile = userProfile.copyWith(
          friendCount: userProfile.friendCount + (increment ? 1 : -1),
        );

        // Update the profile
        _ref
            .read(profileProvider.notifier)
            .updateProfile(updatedProfile.toJson());
      }
    } catch (e) {
      debugPrint('Error updating follower counts: $e');
    }
  }

  /// Perform the actual follow/unfollow API call
  Future<void> _performFollowAction(String userId, bool follow) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // In a real app, this would be an API call:
    // final response = await _apiClient.followUser(userId, follow);
    // if (!response.success) {
    //   throw Exception(response.message);
    // }

    // Mock success
    debugPrint('${follow ? "Following" : "Unfollowed"} user: $userId');
  }
}

/// Provider for social interactions
final socialProvider =
    StateNotifierProvider<SocialNotifier, AsyncValue<Map<String, bool>>>((ref) {
  return SocialNotifier(ref);
});

/// Action state provider for follow/unfollow
final socialActionStateProvider = StateProvider<SocialActionState>((ref) {
  return SocialActionState.idle;
});
