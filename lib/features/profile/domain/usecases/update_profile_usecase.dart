import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/models/user_profile.dart';

/// Use case to update a user profile
class UpdateProfileUseCase {
  final ProfileRepository _repository;

  UpdateProfileUseCase(this._repository);

  /// Update a user profile
  Future<void> execute(UserProfile profile) async {
    return _repository.updateProfile(profile);
  }
}
