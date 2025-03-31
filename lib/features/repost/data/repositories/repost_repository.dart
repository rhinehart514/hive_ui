import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../../models/repost.dart';
import '../../../../models/event.dart';

class RepostRepository {
  final FirebaseFirestore _firestore;
  final CollectionReference _repostsCollection;

  RepostRepository({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _repostsCollection = (firestore ?? FirebaseFirestore.instance).collection('reposts');

  // Create a new repost
  Future<Repost> createRepost({
    required String userId,
    required String eventId,
    required Event event,
    String? text,
    required String contentType,
  }) async {
    try {
      // Create repost object
      final repost = Repost.create(
        userId: userId,
        eventId: eventId,
        text: text,
        originalEventTitle: event.title,
        originalEventImageUrl: event.safeImageUrl,
      );

      // Save to Firestore
      await _repostsCollection.doc(repost.id).set(repost.toFirestore());
      
      // Update event reposts count in a separate collection/document if needed
      // This is optional and depends on your data model
      
      return repost;
    } catch (e) {
      debugPrint('Error creating repost: $e');
      rethrow;
    }
  }

  // Get reposts by user
  Future<List<Repost>> getRepostsByUser(String userId) async {
    try {
      final querySnapshot = await _repostsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Repost.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting user reposts: $e');
      return [];
    }
  }

  // Get reposts for an event
  Future<List<Repost>> getRepostsForEvent(String eventId) async {
    try {
      final querySnapshot = await _repostsCollection
          .where('eventId', isEqualTo: eventId)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => Repost.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error getting event reposts: $e');
      return [];
    }
  }

  // Delete a repost
  Future<void> deleteRepost(String repostId) async {
    try {
      await _repostsCollection.doc(repostId).delete();
    } catch (e) {
      debugPrint('Error deleting repost: $e');
      rethrow;
    }
  }

  // Update a repost
  Future<void> updateRepost(Repost repost) async {
    try {
      await _repostsCollection.doc(repost.id).update(repost.toFirestore());
    } catch (e) {
      debugPrint('Error updating repost: $e');
      rethrow;
    }
  }

  // Like a repost
  Future<void> likeRepost(String repostId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final repostDoc = await transaction.get(_repostsCollection.doc(repostId));
        
        if (!repostDoc.exists) {
          throw Exception('Repost not found');
        }
        
        final repost = Repost.fromFirestore(repostDoc);
        
        if (repost.likedBy.contains(userId)) {
          // User already liked, unlike
          final updatedLikedBy = List<String>.from(repost.likedBy)..remove(userId);
          transaction.update(_repostsCollection.doc(repostId), {
            'likedBy': updatedLikedBy,
            'likeCount': FieldValue.increment(-1),
          });
        } else {
          // User hasn't liked, add like
          final updatedLikedBy = List<String>.from(repost.likedBy)..add(userId);
          transaction.update(_repostsCollection.doc(repostId), {
            'likedBy': updatedLikedBy,
            'likeCount': FieldValue.increment(1),
          });
        }
      });
    } catch (e) {
      debugPrint('Error liking repost: $e');
      rethrow;
    }
  }

  // Stream of reposts for a user's feed
  Stream<List<Repost>> streamUserFeedReposts(List<String> followedUserIds) {
    try {
      // If not following anyone, return empty stream
      if (followedUserIds.isEmpty) {
        return Stream.value([]);
      }
      
      return _repostsCollection
          .where('userId', whereIn: followedUserIds)
          .orderBy('createdAt', descending: true)
          .limit(50) // Reasonable limit for feed
          .snapshots()
          .map((snapshot) => 
              snapshot.docs.map((doc) => Repost.fromFirestore(doc)).toList());
    } catch (e) {
      debugPrint('Error streaming feed reposts: $e');
      return Stream.value([]);
    }
  }
} 