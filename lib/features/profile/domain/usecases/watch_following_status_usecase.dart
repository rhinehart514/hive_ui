import 'package:hive_ui/features/profile/domain/repositories/social_repository.dart';

/// Use case to watch for changes in following status
class WatchFollowingStatusUseCase {
  final SocialRepository _repository;

  WatchFollowingStatusUseCase(this._repository);

  /// Watch for changes in following status
  Stream<bool> execute(String userId) {
    return _repository.watchFollowingStatus(userId);
  }
}
