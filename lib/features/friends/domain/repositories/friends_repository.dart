import '../entities/suggested_friend.dart';

/// Interface defining the operations for friend-related functionality
abstract class FriendsRepository {
  /// Get a list of suggested friends for a user
  Future<List<SuggestedFriend>> getSuggestedFriends({
    required String userId,
    int limit = 5,
  });
  
  /// Send a friend request from one user to another
  Future<bool> sendFriendRequest(String senderId, String receiverId);
} 