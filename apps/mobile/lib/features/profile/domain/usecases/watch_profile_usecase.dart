import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';

/// Use case to watch profile updates in real-time
class WatchProfileUseCase {
  final ProfileRepository _repository;

  WatchProfileUseCase(this._repository);

  /// Stream to watch profile updates in real-time
  Stream<UserProfile?> execute(String userId) {
    return _repository.watchProfile(userId);
  }
}
