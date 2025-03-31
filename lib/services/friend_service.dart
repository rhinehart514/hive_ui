import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_ui/models/friend.dart';
import 'package:hive_ui/providers/activity_provider.dart';

/// Enum for friend request status
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
}

/// Service for managing friend relationships
class FriendService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _friendsCollection = 'friends';
  final String _requestsCollection = 'friend_requests';
  final String _usersCollection = 'user_profiles';

  /// Get all friends for a user
  Future<List<Friend>> getFriends(String userId) async {
    try {
      debugPrint('FriendService: Getting friends for user $userId');

      // Query the friends collection for this user
      final snapshot = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('FriendService: No friends found for user $userId');
        return [];
      }

      // Get the list of friend IDs
      final friendIds =
          snapshot.docs.map((doc) => doc.data()['friendId'] as String).toList();

      // Query the user profiles for these friends
      final friendsList = <Friend>[];
      for (final friendId in friendIds) {
        final userDoc =
            await _firestore.collection(_usersCollection).doc(friendId).get();

        if (userDoc.exists && userDoc.data() != null) {
          final userData = userDoc.data()!;
          friendsList.add(Friend(
            id: userDoc.id,
            name: userData['username'] ?? 'Unknown User',
            major: userData['major'] ?? 'Undeclared',
            year: userData['year'] ?? 'Unknown',
            imageUrl: userData['profileImageUrl'],
            isOnline: userData['isOnline'] ?? false,
            lastActive: userData['lastActive'] != null
                ? (userData['lastActive'] as Timestamp).toDate()
                : DateTime.now(),
            createdAt: userData['createdAt'] != null
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          ));
        }
      }

      debugPrint('FriendService: Found ${friendsList.length} friends');
      return friendsList;
    } catch (e) {
      debugPrint('FriendService: Error getting friends: $e');
      return [];
    }
  }

  /// Send a friend request to another user
  Future<bool> sendFriendRequest(String senderId, String recipientId) async {
    try {
      debugPrint(
          'FriendService: Sending friend request from $senderId to $recipientId');

      // Check if a request already exists
      final existingRequest = await _firestore
          .collection(_requestsCollection)
          .where('senderId', isEqualTo: senderId)
          .where('recipientId', isEqualTo: recipientId)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        debugPrint('FriendService: Request already exists');
        return false;
      }

      // Check if users are already friends
      final existingFriendship = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: senderId)
          .where('friendId', isEqualTo: recipientId)
          .get();

      if (existingFriendship.docs.isNotEmpty) {
        debugPrint('FriendService: Already friends');
        return false;
      }

      // Create the friend request
      await _firestore.collection(_requestsCollection).add({
        'senderId': senderId,
        'recipientId': recipientId,
        'status': FriendRequestStatus.pending.toString().split('.').last,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FriendService: Friend request sent successfully');
      return true;
    } catch (e) {
      debugPrint('FriendService: Error sending friend request: $e');
      return false;
    }
  }

  /// Get all pending friend requests for a user
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    try {
      debugPrint('FriendService: Getting pending requests for user $userId');

      // Query for requests where user is the recipient
      final snapshot = await _firestore
          .collection(_requestsCollection)
          .where('recipientId', isEqualTo: userId)
          .where('status',
              isEqualTo: FriendRequestStatus.pending.toString().split('.').last)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('FriendService: No pending requests found');
        return [];
      }

      // Get sender information for each request
      final requests = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final senderId = data['senderId'] as String;

        // Get sender profile
        final senderDoc =
            await _firestore.collection(_usersCollection).doc(senderId).get();

        if (senderDoc.exists && senderDoc.data() != null) {
          final senderData = senderDoc.data()!;
          requests.add({
            'requestId': doc.id,
            'senderId': senderId,
            'senderName': senderData['username'] ?? 'Unknown User',
            'senderImage': senderData['profileImageUrl'],
            'senderMajor': senderData['major'] ?? 'Undeclared',
            'senderYear': senderData['year'] ?? 'Unknown',
            'createdAt': data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          });
        }
      }

      debugPrint('FriendService: Found ${requests.length} pending requests');
      return requests;
    } catch (e) {
      debugPrint('FriendService: Error getting pending requests: $e');
      return [];
    }
  }

  /// Accept a friend request
  Future<bool> acceptFriendRequest(
      String requestId, String userId, String friendId) async {
    try {
      debugPrint('FriendService: Accepting friend request $requestId');

      // Update the request status
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': FriendRequestStatus.accepted.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Create friendship records for both users (bidirectional)
      final batch = _firestore.batch();

      // User -> Friend
      final userToFriendDoc = _firestore.collection(_friendsCollection).doc();
      batch.set(userToFriendDoc, {
        'userId': userId,
        'friendId': friendId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Friend -> User
      final friendToUserDoc = _firestore.collection(_friendsCollection).doc();
      batch.set(friendToUserDoc, {
        'userId': friendId,
        'friendId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await batch.commit();

      // Get friend profile to log activity
      final friendDoc =
          await _firestore.collection(_usersCollection).doc(friendId).get();

      if (friendDoc.exists && friendDoc.data() != null) {
        final friendName = friendDoc.data()!['username'] ?? 'Unknown User';

        // Log friend activity in activity feed
        final activityService = ActivityService();
        await activityService.logNewFriend(userId, friendName, friendId);
        await activityService.logNewFriend(friendId, friendName, userId);

        // Update friend counts
        await _updateFriendCount(userId);
        await _updateFriendCount(friendId);
      }

      debugPrint('FriendService: Friend request accepted successfully');
      return true;
    } catch (e) {
      debugPrint('FriendService: Error accepting friend request: $e');
      return false;
    }
  }

  /// Reject a friend request
  Future<bool> rejectFriendRequest(String requestId) async {
    try {
      debugPrint('FriendService: Rejecting friend request $requestId');

      // Update the request status
      await _firestore.collection(_requestsCollection).doc(requestId).update({
        'status': FriendRequestStatus.rejected.toString().split('.').last,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FriendService: Friend request rejected successfully');
      return true;
    } catch (e) {
      debugPrint('FriendService: Error rejecting friend request: $e');
      return false;
    }
  }

  /// Remove a friend
  Future<bool> removeFriend(String userId, String friendId) async {
    try {
      debugPrint(
          'FriendService: Removing friend relationship between $userId and $friendId');

      // Delete both friendship records (bidirectional)
      final batch = _firestore.batch();

      // Find and delete user -> friend record
      final userToFriendSnapshot = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: friendId)
          .get();

      for (final doc in userToFriendSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Find and delete friend -> user record
      final friendToUserSnapshot = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: friendId)
          .where('friendId', isEqualTo: userId)
          .get();

      for (final doc in friendToUserSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Update friend counts
      await _updateFriendCount(userId);
      await _updateFriendCount(friendId);

      debugPrint('FriendService: Friend removed successfully');
      return true;
    } catch (e) {
      debugPrint('FriendService: Error removing friend: $e');
      return false;
    }
  }

  /// Update the friend count for a user
  Future<void> _updateFriendCount(String userId) async {
    try {
      // Count the number of friends
      final snapshot = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: userId)
          .get();

      final count = snapshot.docs.length;

      // Update the user's friend count
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .update({'friendCount': count});

      debugPrint('FriendService: Updated friend count for $userId to $count');
    } catch (e) {
      debugPrint('FriendService: Error updating friend count: $e');
    }
  }

  /// Check if two users are friends
  Future<bool> areFriends(String userId, String otherUserId) async {
    try {
      final snapshot = await _firestore
          .collection(_friendsCollection)
          .where('userId', isEqualTo: userId)
          .where('friendId', isEqualTo: otherUserId)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FriendService: Error checking friendship: $e');
      return false;
    }
  }

  /// Check if user has a pending friend request from another user
  Future<bool> hasPendingRequestFrom(String userId, String otherUserId) async {
    try {
      final snapshot = await _firestore
          .collection(_requestsCollection)
          .where('recipientId', isEqualTo: userId)
          .where('senderId', isEqualTo: otherUserId)
          .where('status',
              isEqualTo: FriendRequestStatus.pending.toString().split('.').last)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FriendService: Error checking pending request: $e');
      return false;
    }
  }

  /// Check if there is a pending friend request between two users (in either direction)
  Future<bool> hasPendingRequest(String userId, String otherUserId) async {
    try {
      // Check if user has sent a request to other user
      final sentSnapshot = await _firestore
          .collection(_requestsCollection)
          .where('senderId', isEqualTo: userId)
          .where('recipientId', isEqualTo: otherUserId)
          .where('status',
              isEqualTo: FriendRequestStatus.pending.toString().split('.').last)
          .get();
              
      // Check if user has received a request from other user
      final receivedSnapshot = await _firestore
          .collection(_requestsCollection)
          .where('recipientId', isEqualTo: userId)
          .where('senderId', isEqualTo: otherUserId)
          .where('status',
              isEqualTo: FriendRequestStatus.pending.toString().split('.').last)
          .get();
              
      return sentSnapshot.docs.isNotEmpty || receivedSnapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('FriendService: Error checking pending request: $e');
      return false;
    }
  }
}

/// Provider for the friend service
final friendServiceProvider = Provider<FriendService>((ref) {
  return FriendService();
});
