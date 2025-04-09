import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/models/hivelab_post.dart';
import '../../domain/repositories/hivelab_post_repository.dart';

/// Implementation of the HIVELab post repository using Firestore
class HiveLabPostRepositoryImpl implements HiveLabPostRepository {
  final FirebaseFirestore _firestore;
  final String _collection = 'hive_lab';
  
  /// Constructor
  HiveLabPostRepositoryImpl({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;
  
  @override
  Future<String> createPost({
    required String content,
    required HiveLabPostCategory category,
    required String userId,
    required String userName,
    String? userImage,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'content': content,
        'category': category.displayName,
        'userId': userId,
        'userName': userName,
        'userImage': userImage,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'commentCount': 0,
      });
      
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating HIVELab post: $e');
      throw Exception('Failed to create post: $e');
    }
  }
  
  @override
  Future<HiveLabPost?> getPost(String postId) async {
    try {
      final docSnapshot = await _firestore.collection(_collection).doc(postId).get();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      return HiveLabPost.fromFirestore(docSnapshot);
    } catch (e) {
      debugPrint('Error fetching HIVELab post: $e');
      return null;
    }
  }
  
  @override
  Future<List<HiveLabPost>> getPosts({
    int limit = 20,
    HiveLabPost? lastPost,
    String? category,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      // Apply category filter if provided
      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      
      // Apply pagination if lastPost is provided
      if (lastPost != null) {
        query = query.startAfter([lastPost.createdAt]);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => HiveLabPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching HIVELab posts: $e');
      return [];
    }
  }
  
  @override
  Future<List<HiveLabPost>> getUserPosts(String userId, {
    int limit = 20,
    HiveLabPost? lastPost,
  }) async {
    try {
      Query query = _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .orderBy('createdAt', descending: true)
          .limit(limit);
      
      // Apply pagination if lastPost is provided
      if (lastPost != null) {
        query = query.startAfter([lastPost.createdAt]);
      }
      
      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => HiveLabPost.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('Error fetching user HIVELab posts: $e');
      return [];
    }
  }
  
  @override
  Future<void> updatePost(HiveLabPost post) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(post.id)
          .update(post.toFirestore());
    } catch (e) {
      debugPrint('Error updating HIVELab post: $e');
      throw Exception('Failed to update post: $e');
    }
  }
  
  @override
  Future<void> deletePost(String postId) async {
    try {
      // Instead of deleting, we mark the post as inactive
      await _firestore
          .collection(_collection)
          .doc(postId)
          .update({'status': 'deleted'});
    } catch (e) {
      debugPrint('Error deleting HIVELab post: $e');
      throw Exception('Failed to delete post: $e');
    }
  }
  
  @override
  Future<void> toggleLike(String postId, String userId) async {
    try {
      // Get the current document
      final docRef = _firestore.collection(_collection).doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      
      final post = HiveLabPost.fromFirestore(doc);
      final likes = List<String>.from(post.likes);
      
      // Toggle the like
      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);
      }
      
      // Update the document
      await docRef.update({'likes': likes});
    } catch (e) {
      debugPrint('Error toggling like on HIVELab post: $e');
      throw Exception('Failed to toggle like: $e');
    }
  }
  
  @override
  Future<void> addComment(String postId) async {
    try {
      // Get the current document
      final docRef = _firestore.collection(_collection).doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      
      // Increment the comment count using Firestore's FieldValue.increment
      await docRef.update({
        'commentCount': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('Error adding comment to HIVELab post: $e');
      throw Exception('Failed to add comment: $e');
    }
  }
  
  @override
  Future<void> removeComment(String postId) async {
    try {
      // Get the current document
      final docRef = _firestore.collection(_collection).doc(postId);
      final doc = await docRef.get();
      
      if (!doc.exists) {
        throw Exception('Post not found');
      }
      
      final post = HiveLabPost.fromFirestore(doc);
      
      // Only decrement if the count is greater than 0
      if (post.commentCount > 0) {
        // Decrement the comment count using Firestore's FieldValue.increment
        await docRef.update({
          'commentCount': FieldValue.increment(-1),
        });
      }
    } catch (e) {
      debugPrint('Error removing comment from HIVELab post: $e');
      throw Exception('Failed to remove comment: $e');
    }
  }
} 