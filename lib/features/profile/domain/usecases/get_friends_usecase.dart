import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';
import 'package:hive_ui/models/friend.dart';

/// Use case to get a list of friends for a user
class GetFriendsUseCase {
  final SocialRepository _repository;

  GetFriendsUseCase(this._repository);

  /// Get a list of friends for a user
  Future<List<Friend>> execute(String userId) async {
    return _repository.getFriends(userId);
  }
}
