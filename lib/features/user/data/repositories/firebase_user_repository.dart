import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive_ui/features/user/domain/entities/user.dart';
import 'package:hive_ui/features/user/domain/repositories/user_repository.dart';
import 'package:hive_ui/services/firebase_monitor.dart';

/// Firebase implementation of the UserRepository interface
class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;
  
  /// Constructor
  FirebaseUserRepository({FirebaseFirestore? firestore}) 
    : _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Collection reference for users
  CollectionReference<Map<String, dynamic>> get _usersCollection => 
      _firestore.collection('users');
      
  /// Collection reference for following relationships
  CollectionReference<Map<String, dynamic>> get _followingCollection => 
      _firestore.collection('following');
  
  @override
  Future<List<User>> searchUsers(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      // Search by username or displayName
      // Using a prefix search for Firestore
      final queryEndStr = query + '\uf8ff'; // Unicode trick for prefix search
      
      // First try searching by username (case-sensitive)
      var snapshot = await _usersCollection
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThan: queryEndStr)
          .limit(20)
          .get();
          
      FirebaseMonitor.recordRead();
      
      // If no results, try by displayName (case-insensitive approximation)
      if (snapshot.docs.isEmpty) {
        final lowercaseQuery = query.toLowerCase();
        final lowercaseQueryEnd = lowercaseQuery + '\uf8ff';
        
        snapshot = await _usersCollection
            .where('displayNameLowercase', isGreaterThanOrEqualTo: lowercaseQuery)
            .where('displayNameLowercase', isLessThan: lowercaseQueryEnd)
            .limit(20)
            .get();
            
        FirebaseMonitor.recordRead();
      }
      
      // Convert to User entities
      final users = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _mapToUser(data);
          })
          .toList();
      
      return users;
    } catch (e) {
      debugPrint('❌ Error searching users: $e');
      return [];
    }
  }
  
  @override
  Future<User?> getUserById(String userId) async {
    try {
      final docSnapshot = await _usersCollection.doc(userId).get();
      FirebaseMonitor.recordRead();
      
      if (!docSnapshot.exists) {
        return null;
      }
      
      final data = docSnapshot.data()!;
      data['id'] = docSnapshot.id;
      
      return _mapToUser(data);
    } catch (e) {
      debugPrint('❌ Error getting user by ID: $e');
      return null;
    }
  }
  
  @override
  Future<List<User>> getSuggestedUsers() async {
    try {
      // Get a random sample of users
      // In a real implementation, this would use more sophisticated recommendation logic
      final snapshot = await _usersCollection
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
          
      FirebaseMonitor.recordRead();
      
      final users = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return _mapToUser(data);
          })
          .toList();
      
      return users;
    } catch (e) {
      debugPrint('❌ Error getting suggested users: $e');
      return [];
    }
  }
  
  @override
  Future<List<User>> getFollowingUsers() async {
    try {
      // TODO: Get current user ID from authentication service
      final currentUserId = 'current_user_id';
      
      final followingSnapshot = await _followingCollection
          .where('followerId', isEqualTo: currentUserId)
          .get();
          
      FirebaseMonitor.recordRead();
      
      if (followingSnapshot.docs.isEmpty) {
        return [];
      }
      
      // Get the IDs of users being followed
      final followingIds = followingSnapshot.docs
          .map((doc) => doc.data()['followedId'] as String)
          .toList();
      
      // Fetch users by IDs (in batches if needed)
      final List<User> followingUsers = [];
      
      // Process in batches of 10 to avoid large IN queries
      for (int i = 0; i < followingIds.length; i += 10) {
        final batchIds = followingIds.sublist(
            i, 
            i + 10 > followingIds.length ? followingIds.length : i + 10
        );
        
        final usersSnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
            
        FirebaseMonitor.recordRead();
        
        for (final doc in usersSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          followingUsers.add(_mapToUser(data));
        }
      }
      
      return followingUsers;
    } catch (e) {
      debugPrint('❌ Error getting following users: $e');
      return [];
    }
  }
  
  @override
  Future<List<User>> getFollowerUsers() async {
    try {
      // TODO: Get current user ID from authentication service
      final currentUserId = 'current_user_id';
      
      final followerSnapshot = await _followingCollection
          .where('followedId', isEqualTo: currentUserId)
          .get();
          
      FirebaseMonitor.recordRead();
      
      if (followerSnapshot.docs.isEmpty) {
        return [];
      }
      
      // Get the IDs of users following the current user
      final followerIds = followerSnapshot.docs
          .map((doc) => doc.data()['followerId'] as String)
          .toList();
      
      // Fetch users by IDs (in batches if needed)
      final List<User> followerUsers = [];
      
      // Process in batches of 10 to avoid large IN queries
      for (int i = 0; i < followerIds.length; i += 10) {
        final batchIds = followerIds.sublist(
            i, 
            i + 10 > followerIds.length ? followerIds.length : i + 10
        );
        
        final usersSnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batchIds)
            .get();
            
        FirebaseMonitor.recordRead();
        
        for (final doc in usersSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;
          followerUsers.add(_mapToUser(data));
        }
      }
      
      return followerUsers;
    } catch (e) {
      debugPrint('❌ Error getting follower users: $e');
      return [];
    }
  }
  
  @override
  Future<bool> followUser(String userId) async {
    try {
      // TODO: Get current user ID from authentication service
      final currentUserId = 'current_user_id';
      
      // Check if already following
      final followDoc = await _followingCollection
          .where('followerId', isEqualTo: currentUserId)
          .where('followedId', isEqualTo: userId)
          .limit(1)
          .get();
          
      FirebaseMonitor.recordRead();
      
      if (followDoc.docs.isNotEmpty) {
        // Already following, do nothing
        return true;
      }
      
      // Add following relationship
      await _followingCollection.add({
        'followerId': currentUserId,
        'followedId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      // FirebaseMonitor.recordWrite(); - No recordWrite method available in FirebaseMonitor
      debugPrint('➕ Created following relationship: $currentUserId → $userId');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error following user: $e');
      return false;
    }
  }
  
  @override
  Future<bool> unfollowUser(String userId) async {
    try {
      // TODO: Get current user ID from authentication service
      final currentUserId = 'current_user_id';
      
      // Find the following document
      final followDoc = await _followingCollection
          .where('followerId', isEqualTo: currentUserId)
          .where('followedId', isEqualTo: userId)
          .limit(1)
          .get();
          
      FirebaseMonitor.recordRead();
      
      if (followDoc.docs.isEmpty) {
        // Not following, do nothing
        return true;
      }
      
      // Delete the following relationship
      await _followingCollection.doc(followDoc.docs.first.id).delete();
      // FirebaseMonitor.recordWrite(); - No recordWrite method available in FirebaseMonitor
      debugPrint('➖ Deleted following relationship: $currentUserId → $userId');
      
      return true;
    } catch (e) {
      debugPrint('❌ Error unfollowing user: $e');
      return false;
    }
  }
  
  @override
  Future<void> updateUserRestriction(
    String userId, {
    required bool isRestricted,
    String? reason,
    DateTime? endDate,
    String? restrictedBy,
  }) async {
    try {
      final updateData = {
        'isRestricted': isRestricted,
        'restrictionReason': reason,
        'restrictionEndDate': endDate != null ? Timestamp.fromDate(endDate) : null,
        'restrictedBy': restrictedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      // Remove null values to avoid overwriting with null
      updateData.removeWhere((key, value) => value == null);
      
      await _usersCollection.doc(userId).update(updateData);
      // FirebaseMonitor.recordWrite(); - No recordWrite method available in FirebaseMonitor
      debugPrint('✏️ Updated user restriction status for user $userId: isRestricted=$isRestricted');
    } catch (e) {
      debugPrint('❌ Error updating user restriction: $e');
      throw Exception('Failed to update user restriction: $e');
    }
  }
  
  /// Map Firestore data to User entity
  User _mapToUser(Map<String, dynamic> data) {
    // Handle potential null or missing values
    return User(
      id: data['id'] as String,
      username: data['username'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      profilePicture: data['profilePicture'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      isVerified: data['isVerified'] as bool? ?? false,
      isRestricted: data['isRestricted'] as bool? ?? false,
      restrictionReason: data['restrictionReason'] as String?,
      restrictionEndDate: data['restrictionEndDate'] != null 
          ? (data['restrictionEndDate'] as Timestamp).toDate()
          : null,
      restrictedBy: data['restrictedBy'] as String?,
    );
  }
} 