import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';

/// Provider for getting all suggested friends
final suggestedFriendsProvider = FutureProvider<List<SuggestedFriend>>((ref) async {
  // Current user ID (in a real app this would come from auth provider)
  const String currentUserId = 'goose_chaser_123';
  
  // Get the user's profile to access their interests, major, etc.
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(currentUserId)
      .get();
  
  if (!userDoc.exists) {
    return [];
  }
  
  final userData = userDoc.data()!;
  final userInterests = List<String>.from(userData['interests'] ?? []);
  final userMajor = userData['major'] as String?;
  final userResidence = userData['residence'] as String?;
  
  // Get users who might be suggested friends
  final usersQuery = await FirebaseFirestore.instance
      .collection('users')
      .where(FieldPath.documentId, isNotEqualTo: currentUserId)
      .limit(50)
      .get();
  
  // Get existing friends to exclude them
  final friendsQuery = await FirebaseFirestore.instance
      .collection('friends')
      .where('userId1', isEqualTo: currentUserId)
      .get();
  
  final friendsQuery2 = await FirebaseFirestore.instance
      .collection('friends')
      .where('userId2', isEqualTo: currentUserId)
      .get();
  
  // Combine both queries to get all friends
  final Set<String> friendIds = {};
  for (final doc in friendsQuery.docs) {
    friendIds.add(doc['userId2'] as String);
  }
  for (final doc in friendsQuery2.docs) {
    friendIds.add(doc['userId1'] as String);
  }
  
  // Get pending friend requests to show proper UI state
  final sentRequestsQuery = await FirebaseFirestore.instance
      .collection('friendRequests')
      .where('senderId', isEqualTo: currentUserId)
      .where('status', isEqualTo: 'pending')
      .get();
  
  final Set<String> pendingRequestIds = {};
  for (final doc in sentRequestsQuery.docs) {
    pendingRequestIds.add(doc['receiverId'] as String);
  }
  
  // Process potential friends and apply matching criteria
  final List<SuggestedFriend> suggestedFriends = [];
  
  for (final doc in usersQuery.docs) {
    // Skip if this is already a friend
    if (friendIds.contains(doc.id)) {
      continue;
    }
    
    final data = doc.data();
    
    // Try to find a match criterion
    MatchCriteria? matchCriteria;
    String? matchValue;
    
    // Check for same major
    final usersMajor = data['major'] as String?;
    if (usersMajor != null && usersMajor == userMajor) {
      matchCriteria = MatchCriteria.major;
      matchValue = usersMajor;
    }
    
    // Check for same residence
    if (matchCriteria == null) {
      final usersResidence = data['residence'] as String?;
      if (usersResidence != null && usersResidence == userResidence) {
        matchCriteria = MatchCriteria.residence;
        matchValue = usersResidence;
      }
    }
    
    // Check for shared interests
    if (matchCriteria == null) {
      final List<String> theirInterests = List<String>.from(data['interests'] ?? []);
      final sharedInterests = userInterests
          .where((interest) => theirInterests.contains(interest))
          .toList();
      
      if (sharedInterests.isNotEmpty) {
        matchCriteria = MatchCriteria.interest;
        matchValue = sharedInterests.first;
      }
    }
    
    // If we found a match, add them as a suggested friend
    if (matchCriteria != null && matchValue != null) {
      suggestedFriends.add(
        SuggestedFriend.fromFirestore(
          doc,
          matchCriteria,
          matchValue,
          pendingRequestIds.contains(doc.id),
          friendIds.contains(doc.id),
        ),
      );
    }
  }
  
  return suggestedFriends;
});

/// Provider for filtering suggested friends by criteria
final filteredSuggestedFriendsProvider = FutureProvider.family<List<SuggestedFriend>, MatchCriteria?>(
  (ref, criteria) async {
    final allSuggestions = await ref.watch(suggestedFriendsProvider.future);
    
    if (criteria == null) {
      return allSuggestions;
    }
    
    return allSuggestions
        .where((friend) => friend.matchCriteria == criteria)
        .toList();
  },
);

/// Provider for sending a friend request
final sendFriendRequestProvider = FutureProvider.family<bool, String>(
  (ref, friendId) async {
    try {
      // Current user ID (in a real app this would come from auth provider)
      const String currentUserId = 'goose_chaser_123';
      
      // Create a new friend request
      await FirebaseFirestore.instance.collection('friendRequests').add({
        'senderId': currentUserId,
        'receiverId': friendId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // Refresh the suggested friends list
      ref.invalidate(suggestedFriendsProvider);
      
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  },
); 