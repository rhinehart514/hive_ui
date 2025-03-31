import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/suggested_friend.dart';
import '../../domain/repositories/friends_repository.dart';

class FriendsRepositoryImpl implements FriendsRepository {
  final FirebaseFirestore _firestore;

  FriendsRepositoryImpl({FirebaseFirestore? firestore}) 
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<SuggestedFriend>> getSuggestedFriends({
    required String userId, 
    int limit = 5
  }) async {
    try {
      // Get the user's profile to extract interests, major, and location
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final List<String> userInterests = List<String>.from(userData['interests'] ?? []);
      final String? userMajor = userData['major'];
      final String? userLocation = userData['location'];
      
      // Existing connections to exclude
      final List<String> connections = List<String>.from(userData['connections'] ?? []);
      connections.add(userId); // Add self to exclusion list
      
      // Query for users with matching interests
      final interestMatches = await _firestore
          .collection('users')
          .where('interests', arrayContainsAny: userInterests.isNotEmpty ? userInterests : [''])
          .where(FieldPath.documentId, whereNotIn: connections.isEmpty ? [''] : connections.take(10).toList())
          .limit(limit)
          .get();
          
      List<SuggestedFriend> suggestions = [];
      
      // Process interest matches
      for (var doc in interestMatches.docs) {
        final data = doc.data();
        final matchingInterests = List<String>.from(data['interests'] ?? [])
            .where((interest) => userInterests.contains(interest))
            .toList();
            
        if (matchingInterests.isNotEmpty) {
          suggestions.add(SuggestedFriend(
            id: doc.id,
            name: data['displayName'] ?? 'Anonymous',
            profileImage: data['profileImageUrl'],
            matchCriteria: MatchCriteria.interest,
            matchValue: matchingInterests.first,
            status: data['status'] ?? '',
            isRequestSent: false,
          ));
        }
      }
      
      // If we need more suggestions, find major matches
      if (suggestions.length < limit && userMajor != null && userMajor.isNotEmpty) {
        final majorMatches = await _firestore
            .collection('users')
            .where('major', isEqualTo: userMajor)
            .where(FieldPath.documentId, whereNotIn: [
              ...connections, 
              ...suggestions.map((s) => s.id).toList()
            ])
            .limit(limit - suggestions.length)
            .get();
            
        for (var doc in majorMatches.docs) {
          final data = doc.data();
          suggestions.add(SuggestedFriend(
            id: doc.id,
            name: data['displayName'] ?? 'Anonymous',
            profileImage: data['profileImageUrl'],
            matchCriteria: MatchCriteria.major,
            matchValue: userMajor,
            status: data['status'] ?? '',
            isRequestSent: false,
          ));
        }
      }
      
      // If we still need more, find location matches
      if (suggestions.length < limit && userLocation != null && userLocation.isNotEmpty) {
        final locationMatches = await _firestore
            .collection('users')
            .where('location', isEqualTo: userLocation)
            .where(FieldPath.documentId, whereNotIn: [
              ...connections, 
              ...suggestions.map((s) => s.id).toList()
            ])
            .limit(limit - suggestions.length)
            .get();
            
        for (var doc in locationMatches.docs) {
          final data = doc.data();
          suggestions.add(SuggestedFriend(
            id: doc.id,
            name: data['displayName'] ?? 'Anonymous',
            profileImage: data['profileImageUrl'],
            matchCriteria: MatchCriteria.residence,
            matchValue: userLocation,
            status: data['status'] ?? '',
            isRequestSent: false,
          ));
        }
      }
      
      // Check if any friend requests have already been sent
      if (suggestions.isNotEmpty) {
        final sentRequests = await _firestore
            .collection('friendRequests')
            .where('senderId', isEqualTo: userId)
            .where('receiverId', whereIn: suggestions.map((s) => s.id).toList())
            .get();
            
        final requestReceiverIds = sentRequests.docs.map((doc) => doc.data()['receiverId'] as String).toList();
        
        // Mark suggestions that already have a friend request sent
        suggestions = suggestions.map((suggestion) => 
          suggestion.copyWith(isRequestSent: requestReceiverIds.contains(suggestion.id))
        ).toList();
      }
      
      return suggestions;
    } catch (e) {
      print('Error getting suggested friends: $e');
      return [];
    }
  }
  
  @override
  Future<bool> sendFriendRequest(String senderId, String receiverId) async {
    try {
      // Check if a request already exists
      final existingRequest = await _firestore
          .collection('friendRequests')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: receiverId)
          .limit(1)
          .get();
          
      if (existingRequest.docs.isNotEmpty) {
        return false; // Request already exists
      }
      
      // Create a new friend request
      await _firestore.collection('friendRequests').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
      
      return true;
    } catch (e) {
      print('Error sending friend request: $e');
      return false;
    }
  }
} 