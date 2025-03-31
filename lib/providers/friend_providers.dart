import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/services/friend_service.dart';
import 'package:hive_ui/models/friend.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Provider for the friend service
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});

/// Provider to check if two users are friends
final areFriendsProvider = FutureProvider.family<bool, ({String userId, String friendId})>((ref, params) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.areFriends(params.userId, params.friendId);
});

/// Provider to check if there's a pending friend request
final hasPendingRequestProvider = FutureProvider.family<bool, ({String userId, String friendId})>((ref, params) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.hasPendingRequest(params.userId, params.friendId);
});

/// Provider for the current user's friends list
final userFriendsProvider = FutureProvider.autoDispose<List<Friend>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return [];
  }
  
  return await friendService.getFriends(currentUser.uid);
});

/// Provider for pending friend requests
final pendingFriendRequestsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final friendService = ref.watch(friendServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return [];
  }
  
  return await friendService.getPendingRequests(currentUser.uid);
});

/// Provider to send a friend request
final sendFriendRequestProvider = FutureProvider.family<bool, String>((ref, recipientId) async {
  final friendService = ref.watch(friendServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return false;
  }
  
  return await friendService.sendFriendRequest(currentUser.uid, recipientId);
});

/// Provider to accept a friend request
final acceptFriendRequestProvider = FutureProvider.family<bool, ({String requestId, String friendId})>((ref, params) async {
  final friendService = ref.watch(friendServiceProvider);
  final currentUser = FirebaseAuth.instance.currentUser;
  
  if (currentUser == null) {
    return false;
  }
  
  return await friendService.acceptFriendRequest(params.requestId, currentUser.uid, params.friendId);
});

/// Provider to reject a friend request
final rejectFriendRequestProvider = FutureProvider.family<bool, String>((ref, requestId) async {
  final friendService = ref.watch(friendServiceProvider);
  return await friendService.rejectFriendRequest(requestId);
}); 