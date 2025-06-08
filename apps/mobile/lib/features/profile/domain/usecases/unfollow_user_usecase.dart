import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';

/// Use case to unfollow a user
class UnfollowUserUseCase {
  final SocialRepository _repository;

  UnfollowUserUseCase(this._repository);

  /// Unfollow a user
  Future<void> execute(String userId) async {
    return _repository.unfollowUser(userId);
  }
}
