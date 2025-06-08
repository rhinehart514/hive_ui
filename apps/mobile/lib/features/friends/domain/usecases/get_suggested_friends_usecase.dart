import 'package:hive_ui/features/friends/domain/entities/suggested_friend.dart';
import 'package:hive_ui/features/friends/domain/repositories/suggested_friend_repository.dart';

class GetSuggestedFriendsParams {
  final int limit;
  final bool excludeExistingFriends;
  final bool excludePendingRequests;
  
  const GetSuggestedFriendsParams({
    this.limit = 10,
    this.excludeExistingFriends = true,
    this.excludePendingRequests = true,
  });
}

class GetSuggestedFriendsUseCase {
  final SuggestedFriendRepository repository;
  
  GetSuggestedFriendsUseCase(this.repository);
  
  Future<List<SuggestedFriend>> call(GetSuggestedFriendsParams params) async {
    return await repository.getSuggestedFriends(
      limit: params.limit,
      excludeExistingFriends: params.excludeExistingFriends,
      excludePendingRequests: params.excludePendingRequests,
    );
  }
} 