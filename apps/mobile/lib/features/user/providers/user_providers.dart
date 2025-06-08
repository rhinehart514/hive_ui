import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/user/data/repositories/firebase_user_repository.dart';
import 'package:hive_ui/features/user/domain/repositories/user_repository.dart';

/// Provider for UserRepository interface
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return FirebaseUserRepository();
});

/// Provider for searching users
final userSearchProvider = FutureProvider.family<List<dynamic>, String>((ref, query) async {
  final repository = ref.watch(userRepositoryProvider);
  if (query.trim().isEmpty) {
    return [];
  }
  return repository.searchUsers(query);
});

/// Provider for getting user by ID
final userByIdProvider = FutureProvider.family<dynamic, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getUserById(userId);
});

/// Provider for suggested users
final suggestedUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getSuggestedUsers();
});

/// Provider for following users
final followingUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getFollowingUsers();
});

/// Provider for follower users
final followerUsersProvider = FutureProvider<List<dynamic>>((ref) async {
  final repository = ref.watch(userRepositoryProvider);
  return repository.getFollowerUsers();
});

/// Provider function to follow a user
final followUserProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  final result = await repository.followUser(userId);
  
  // Refresh related providers on success
  if (result) {
    ref.invalidate(followingUsersProvider);
    ref.invalidate(followerUsersProvider);
  }
  
  return result;
});

/// Provider function to unfollow a user
final unfollowUserProvider = FutureProvider.family<bool, String>((ref, userId) async {
  final repository = ref.watch(userRepositoryProvider);
  final result = await repository.unfollowUser(userId);
  
  // Refresh related providers on success
  if (result) {
    ref.invalidate(followingUsersProvider);
    ref.invalidate(followerUsersProvider);
  }
  
  return result;
}); 