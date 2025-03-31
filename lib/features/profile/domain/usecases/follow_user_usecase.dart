import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';

/// Use case to follow a user
class FollowUserUseCase {
  final SocialRepository _repository;

  FollowUserUseCase(this._repository);

  /// Follow a user
  Future<void> execute(String userId) async {
    return _repository.followUser(userId);
  }
}
