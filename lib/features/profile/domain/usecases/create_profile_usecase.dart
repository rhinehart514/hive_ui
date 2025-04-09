import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';

/// Use case to create a new user profile
class CreateProfileUseCase {
  final ProfileRepository _repository;

  CreateProfileUseCase(this._repository);

  /// Create a new user profile
  Future<void> execute(UserProfile profile) async {
    return _repository.createProfile(profile);
  }
}
