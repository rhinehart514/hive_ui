import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';

/// Repository interface for suggested friends functionality
abstract class SuggestedFriendRepository {
  /// Get a list of suggested friends for the current user
  Future<List<SuggestedFriend>> getSuggestedFriends({
    required int limit, 
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  });
  
  /// Get suggested friends based on matching major
  Future<List<SuggestedFriend>> getSuggestedFriendsByMajor({
    required String major,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  });
  
  /// Get suggested friends based on matching residence
  Future<List<SuggestedFriend>> getSuggestedFriendsByResidence({
    required String residence,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  });
  
  /// Get suggested friends based on matching interests
  Future<List<SuggestedFriend>> getSuggestedFriendsByInterests({
    required List<String> interests,
    required int limit,
    bool excludeExistingFriends = true,
    bool excludePendingRequests = true,
  });
} 