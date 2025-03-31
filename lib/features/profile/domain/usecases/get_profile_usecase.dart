import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Use case to get a user profile
class GetProfileUseCase {
  final ProfileRepository _repository;

  GetProfileUseCase(this._repository);

  /// Get a user profile by ID (or current user if ID is not provided)
  Future<UserProfile?> execute([String? userId]) async {
    return _repository.getProfile(userId);
  }
}
