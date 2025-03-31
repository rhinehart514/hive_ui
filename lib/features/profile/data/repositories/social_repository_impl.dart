import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';
import 'package:hive_ui/models/friend.dart';

/// Implementation of the social repository for managing social connections
class SocialRepositoryImpl implements SocialRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  /// Collection names
  static const String _usersCollection = 'users';
  static const String _followersCollection = 'followers';
  static const String _followingCollection = 'following';
  static const String _friendsCollection = 'friends';

  SocialRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  @override
  Future<bool> isFollowing(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;

      final doc = await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .collection(_followingCollection)
          .doc(userId)
          .get();

      return doc.exists;
    } catch (e) {
      debugPrint('SocialRepositoryImpl: Error checking if following: $e');
      return false;
    }
  }

  @override
  Future<void> followUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Don't allow following yourself
      if (currentUser.uid == userId) {
        throw Exception('Cannot follow yourself');
      }

      // Check if already following
      final isAlreadyFollowing = await isFollowing(userId);
      if (isAlreadyFollowing) {
        return; // Already following, no need to do anything
      }

      // Add to current user's following collection
      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .collection(_followingCollection)
          .doc(userId)
          .set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Add to target user's followers collection
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followersCollection)
          .doc(currentUser.uid)
          .set({
        'followedAt': FieldValue.serverTimestamp(),
      });

      // Increment follower count for target user
      await _firestore.collection(_usersCollection).doc(userId).update({
        'followerCount': FieldValue.increment(1),
      });

      // Increment following count for current user
      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .update({
        'followingCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('SocialRepositoryImpl: Error following user: $e');
      throw Exception('Failed to follow user: $e');
    }
  }

  @override
  Future<void> unfollowUser(String userId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }

      // Check if actually following
      final isActuallyFollowing = await isFollowing(userId);
      if (!isActuallyFollowing) {
        return; // Not following, no need to do anything
      }

      // Remove from current user's following collection
      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .collection(_followingCollection)
          .doc(userId)
          .delete();

      // Remove from target user's followers collection
      await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_followersCollection)
          .doc(currentUser.uid)
          .delete();

      // Decrement follower count for target user
      await _firestore.collection(_usersCollection).doc(userId).update({
        'followerCount': FieldValue.increment(-1),
      });

      // Decrement following count for current user
      await _firestore
          .collection(_usersCollection)
          .doc(currentUser.uid)
          .update({
        'followingCount': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('SocialRepositoryImpl: Error unfollowing user: $e');
      throw Exception('Failed to unfollow user: $e');
    }
  }

  @override
  Future<List<Friend>> getFriends(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_friendsCollection)
          .get();

      if (snapshot.docs.isEmpty) {
        return [];
      }

      final futures = snapshot.docs.map((doc) async {
        final friendId = doc.id;
        final userData =
            await _firestore.collection(_usersCollection).doc(friendId).get();

        if (!userData.exists) {
          return null;
        }

        final data = userData.data()!;

        return Friend(
          id: friendId,
          name: data['displayName'] as String? ?? 'Unknown',
          major: data['major'] as String? ?? 'Unknown',
          year: data['year'] as String? ?? 'Unknown',
          imageUrl: data['profileImageUrl'] as String? ?? '',
          isOnline: data['isOnline'] as bool? ?? false,
          lastActive:
              (data['lastActive'] as Timestamp?)?.toDate() ?? DateTime.now(),
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();

      final friends = await Future.wait(futures);
      return friends.where((friend) => friend != null).cast<Friend>().toList();
    } catch (e) {
      debugPrint('SocialRepositoryImpl: Error getting friends: $e');
      return [];
    }
  }

  @override
  Stream<bool> watchFollowingStatus(String userId) {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(false);
    }

    return _firestore
        .collection(_usersCollection)
        .doc(currentUser.uid)
        .collection(_followingCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists);
  }
}
