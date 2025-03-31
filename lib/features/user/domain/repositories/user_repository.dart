import '../entities/user.dart';

/// Interface for accessing user data
abstract class UserRepository {
  /// Search for users based on a query string
  Future<List<User>> searchUsers(String query);
  
  /// Get a user by their ID
  Future<User?> getUserById(String userId);
  
  /// Get a list of suggested users to connect with
  Future<List<User>> getSuggestedUsers();
  
  /// Get a list of users the current user is following
  Future<List<User>> getFollowingUsers();
  
  /// Get a list of users who follow the current user
  Future<List<User>> getFollowerUsers();
  
  /// Follow a user
  Future<bool> followUser(String userId);
  
  /// Unfollow a user
  Future<bool> unfollowUser(String userId);
} 