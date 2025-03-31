import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';

/// Use case to check if a user is being followed
class IsFollowingUseCase {
  final SocialRepository _repository;

  IsFollowingUseCase(this._repository);

  /// Check if a user is being followed
  Future<bool> execute(String userId) async {
    return _repository.isFollowing(userId);
  }
}
