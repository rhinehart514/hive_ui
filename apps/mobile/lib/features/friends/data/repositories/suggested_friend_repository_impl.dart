import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/domain/repositories/suggested_friend_repository.dart';
import 'package:hive_ui/models/friend.dart';
import 'package:hive_ui/services/friend_service.dart';

class SuggestedFriendRepositoryImpl implements SuggestedFriendRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FriendService _friendService;
  
  SuggestedFriendRepositoryImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FriendService? friendService,
  }) : 
    _firestore = firestore ?? FirebaseFirestore.instance,
    _auth = auth ?? FirebaseAuth.instance,
    _friendService = friendService ?? FriendService();
    
  @override
  Future<List<SuggestedFriend>> getSuggestedFriends({
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      // Get current user profile
      final userDoc = await _firestore
          .collection('user_profiles')
          .doc(currentUser.uid)
          .get();
          
      if (!userDoc.exists || userDoc.data() == null) {
        return [];
      }
      
      final userData = userDoc.data()!;
      final userMajor = userData['major'] as String? ?? '';
      final userResidence = userData['residence'] as String? ?? '';
      final userInterests = List<String>.from(userData['interests'] ?? []);
      
      // Combine suggested friends from different criteria
      final majorSuggestions = await getSuggestedFriendsByMajor(
        major: userMajor,
        limit: limit ~/ 3, // Allocate roughly 1/3 of results to major matches
        excludeExistingFriends: excludeExistingFriends,
        excludePendingRequests: excludePendingRequests,
      );
      
      final residenceSuggestions = await getSuggestedFriendsByResidence(
        residence: userResidence,
        limit: limit ~/ 3, // Allocate roughly 1/3 of results to residence matches
        excludeExistingFriends: excludeExistingFriends,
        excludePendingRequests: excludePendingRequests,
      );
      
      final interestSuggestions = await getSuggestedFriendsByInterests(
        interests: userInterests,
        limit: limit ~/ 3, // Allocate roughly 1/3 of results to interest matches
        excludeExistingFriends: excludeExistingFriends,
        excludePendingRequests: excludePendingRequests,
      );
      
      // Combine and remove duplicates
      final allSuggestions = [
        ...majorSuggestions, 
        ...residenceSuggestions, 
        ...interestSuggestions
      ];
      
      final uniqueSuggestions = <SuggestedFriend>[];
      final uniqueIds = <String>{};
      
      for (final suggestion in allSuggestions) {
        if (!uniqueIds.contains(suggestion.id)) {
          uniqueSuggestions.add(suggestion);
          uniqueIds.add(suggestion.id);
          
          if (uniqueSuggestions.length >= limit) {
            break;
          }
        }
      }
      
      return uniqueSuggestions;
    } catch (e) {
      debugPrint('Error getting suggested friends: $e');
      return [];
    }
  }
  
  @override
  Future<List<SuggestedFriend>> getSuggestedFriendsByMajor({
    required String major,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  }) async {
    try {
      if (major.isEmpty) {
        return [];
      }
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      var query = _firestore
          .collection('user_profiles')
          .where('major', isEqualTo: major)
          .limit(limit * 3); // Query more to account for filtering
      
      final querySnapshot = await query.get();
      
      return _processSuggestions(
        querySnapshot.docs,
        currentUser.uid,
        MatchCriteria.major,
        major,
        limit,
        excludeExistingFriends,
        excludePendingRequests,
      );
    } catch (e) {
      debugPrint('Error getting suggested friends by major: $e');
      return [];
    }
  }
  
  @override
  Future<List<SuggestedFriend>> getSuggestedFriendsByResidence({
    required String residence,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  }) async {
    try {
      if (residence.isEmpty) {
        return [];
      }
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      var query = _firestore
          .collection('user_profiles')
          .where('residence', isEqualTo: residence)
          .limit(limit * 3); // Query more to account for filtering
      
      final querySnapshot = await query.get();
      
      return _processSuggestions(
        querySnapshot.docs,
        currentUser.uid,
        MatchCriteria.residence,
        residence,
        limit,
        excludeExistingFriends,
        excludePendingRequests,
      );
    } catch (e) {
      debugPrint('Error getting suggested friends by residence: $e');
      return [];
    }
  }
  
  @override
  Future<List<SuggestedFriend>> getSuggestedFriendsByInterests({
    required List<String> interests,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  }) async {
    try {
      if (interests.isEmpty) {
        return [];
      }
      
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return [];
      }
      
      // Firestore doesn't support direct array contains any with a list from a variable
      // So we'll query for each interest and combine results
      final allResults = <DocumentSnapshot>[];
      
      // Limit the number of interests we query to avoid too many Firestore calls
      final queryInterests = interests.take(3).toList();
      
      for (final interest in queryInterests) {
        var query = _firestore
            .collection('user_profiles')
            .where('interests', arrayContains: interest)
            .limit(limit);
            
        final querySnapshot = await query.get();
        allResults.addAll(querySnapshot.docs);
      }
      
      // Process results for each interest
      final Map<String, SuggestedFriend> matchesByUser = {};
      
      for (final doc in allResults) {
        final userId = doc.id;
        final data = doc.data() as Map<String, dynamic>;
        
        // Skip current user
        if (userId == currentUser.uid) {
          continue;
        }
        
        final userInterests = List<String>.from(data['interests'] ?? []);
        
        // Find matching interests
        final matchingInterests = interests
            .where((interest) => userInterests.contains(interest))
            .toList();
            
        if (matchingInterests.isNotEmpty) {
          // Use the first matching interest as the match value
          final matchValue = matchingInterests.first;
          
          // Create a Friend object
          final friend = Friend(
            id: userId,
            name: data['username'] ?? 'Unknown User',
            major: data['major'] ?? 'Undeclared',
            year: data['year'] ?? 'Unknown',
            imageUrl: data['profileImageUrl'],
            isOnline: data['isOnline'] ?? false,
            lastActive: data['lastActive'] != null
                ? (data['lastActive'] as Timestamp).toDate()
                : DateTime.now(),
            createdAt: data['createdAt'] != null
                ? (data['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
          );
          
          // Convert to SuggestedFriend
          final suggestedFriend = SuggestedFriend.fromFriend(
            friend,
            MatchCriteria.interest,
            matchValue,
          );
          
          // Add to map, with number of matching interests as priority
          matchesByUser[userId] = suggestedFriend;
        }
      }
      
      // Convert map to list
      final suggestions = matchesByUser.values.toList();
      
      return _filterSuggestions(
        suggestions,
        currentUser.uid,
        limit,
        excludeExistingFriends,
        excludePendingRequests,
      );
    } catch (e) {
      debugPrint('Error getting suggested friends by interests: $e');
      return [];
    }
  }
  
  /// Process query results into suggested friends
  Future<List<SuggestedFriend>> _processSuggestions(
    List<DocumentSnapshot> docs,
    String currentUserId,
    MatchCriteria criteria,
    String matchValue,
    int limit,
    bool excludeExistingFriends,
    bool excludePendingRequests,
  ) async {
    final suggestions = <SuggestedFriend>[];
    
    for (final doc in docs) {
      final userId = doc.id;
      
      // Skip current user
      if (userId == currentUserId) {
        continue;
      }
      
      final data = doc.data() as Map<String, dynamic>;
      
      // Create a Friend object
      final friend = Friend(
        id: userId,
        name: data['username'] ?? 'Unknown User',
        major: data['major'] ?? 'Undeclared',
        year: data['year'] ?? 'Unknown',
        imageUrl: data['profileImageUrl'],
        isOnline: data['isOnline'] ?? false,
        lastActive: data['lastActive'] != null
            ? (data['lastActive'] as Timestamp).toDate()
            : DateTime.now(),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : DateTime.now(),
      );
      
      // Convert to SuggestedFriend
      final suggestedFriend = SuggestedFriend.fromFriend(
        friend,
        criteria,
        matchValue,
      );
      
      suggestions.add(suggestedFriend);
    }
    
    return _filterSuggestions(
      suggestions,
      currentUserId,
      limit,
      excludeExistingFriends,
      excludePendingRequests,
    );
  }
  
  /// Filter suggestions to exclude existing friends and pending requests
  Future<List<SuggestedFriend>> _filterSuggestions(
    List<SuggestedFriend> suggestions,
    String currentUserId,
    int limit,
    bool excludeExistingFriends,
    bool excludePendingRequests,
  ) async {
    if (!excludeExistingFriends && !excludePendingRequests) {
      return suggestions.take(limit).toList();
    }
    
    final filteredSuggestions = <SuggestedFriend>[];
    
    for (final suggestion in suggestions) {
      if (filteredSuggestions.length >= limit) {
        break;
      }
      
      bool shouldInclude = true;
      
      if (excludeExistingFriends) {
        final isFriend = await _friendService.areFriends(
          currentUserId, 
          suggestion.id,
        );
        
        if (isFriend) {
          shouldInclude = false;
        }
      }
      
      if (shouldInclude && excludePendingRequests) {
        final hasPendingRequest = await _friendService.hasPendingRequest(
          currentUserId, 
          suggestion.id,
        );
        
        if (hasPendingRequest) {
          shouldInclude = false;
        }
      }
      
      if (shouldInclude) {
        filteredSuggestions.add(suggestion);
      }
    }
    
    return filteredSuggestions;
  }
} 