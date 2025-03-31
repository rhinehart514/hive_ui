import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/repositories/social_repository_impl.dart';
import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';
import 'package:hive_ui/features/profile/domain/usecases/follow_user_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/get_friends_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/is_following_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/unfollow_user_usecase.dart';
import 'package:hive_ui/features/profile/domain/usecases/watch_following_status_usecase.dart';
import 'package:hive_ui/models/friend.dart';

// Repository provider
final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl();
});

// Use case providers
final followUserUseCaseProvider = Provider<FollowUserUseCase>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return FollowUserUseCase(repository);
});

final unfollowUserUseCaseProvider = Provider<UnfollowUserUseCase>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return UnfollowUserUseCase(repository);
});

final isFollowingUseCaseProvider = Provider<IsFollowingUseCase>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return IsFollowingUseCase(repository);
});

final getFriendsUseCaseProvider = Provider<GetFriendsUseCase>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return GetFriendsUseCase(repository);
});

final watchFollowingStatusUseCaseProvider =
    Provider<WatchFollowingStatusUseCase>((ref) {
  final repository = ref.watch(socialRepositoryProvider);
  return WatchFollowingStatusUseCase(repository);
});

// Following status for a specific user
final followingStatusProvider =
    StreamProvider.family<bool, String>((ref, userId) {
  final watchFollowingStatusUseCase =
      ref.watch(watchFollowingStatusUseCaseProvider);
  return watchFollowingStatusUseCase.execute(userId);
});

// Friends list for a specific user
final friendsProvider =
    FutureProvider.family<List<Friend>, String>((ref, userId) async {
  final getFriendsUseCase = ref.watch(getFriendsUseCaseProvider);
  return getFriendsUseCase.execute(userId);
});

// Social operations notifier
class SocialNotifier extends StateNotifier<AsyncValue<void>> {
  final FollowUserUseCase _followUserUseCase;
  final UnfollowUserUseCase _unfollowUserUseCase;
  final IsFollowingUseCase _isFollowingUseCase;

  SocialNotifier({
    required FollowUserUseCase followUserUseCase,
    required UnfollowUserUseCase unfollowUserUseCase,
    required IsFollowingUseCase isFollowingUseCase,
  })  : _followUserUseCase = followUserUseCase,
        _unfollowUserUseCase = unfollowUserUseCase,
        _isFollowingUseCase = isFollowingUseCase,
        super(const AsyncValue.data(null));

  // Follow a user
  Future<void> followUser(String userId) async {
    state = const AsyncValue.loading();

    try {
      await _followUserUseCase.execute(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('SocialNotifier: Error following user: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Unfollow a user
  Future<void> unfollowUser(String userId) async {
    state = const AsyncValue.loading();

    try {
      await _unfollowUserUseCase.execute(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('SocialNotifier: Error unfollowing user: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Toggle follow status
  Future<void> toggleFollow(String userId) async {
    state = const AsyncValue.loading();

    try {
      final isFollowing = await _isFollowingUseCase.execute(userId);

      if (isFollowing) {
        await _unfollowUserUseCase.execute(userId);
      } else {
        await _followUserUseCase.execute(userId);
      }

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('SocialNotifier: Error toggling follow: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  // Initialize following status
  Future<void> initializeFollowingStatus(String userId) async {
    state = const AsyncValue.loading();

    try {
      await _isFollowingUseCase.execute(userId);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('SocialNotifier: Error initializing following status: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}

// Social provider
final socialProvider =
    StateNotifierProvider<SocialNotifier, AsyncValue<void>>((ref) {
  final followUserUseCase = ref.watch(followUserUseCaseProvider);
  final unfollowUserUseCase = ref.watch(unfollowUserUseCaseProvider);
  final isFollowingUseCase = ref.watch(isFollowingUseCaseProvider);

  return SocialNotifier(
    followUserUseCase: followUserUseCase,
    unfollowUserUseCase: unfollowUserUseCase,
    isFollowingUseCase: isFollowingUseCase,
  );
});
