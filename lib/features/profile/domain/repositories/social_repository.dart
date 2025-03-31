import 'package:hive_ui/models/friend.dart';

/// Repository for social operations like following, unfollowing, and getting friends
abstract class SocialRepository {
  /// Check if the current user is following another user
  Future<bool> isFollowing(String userId);

  /// Follow a user
  Future<void> followUser(String userId);

  /// Unfollow a user
  Future<void> unfollowUser(String userId);

  /// Get a list of friends for a user
  Future<List<Friend>> getFriends(String userId);

  /// Watch for changes in following status
  Stream<bool> watchFollowingStatus(String userId);
}
