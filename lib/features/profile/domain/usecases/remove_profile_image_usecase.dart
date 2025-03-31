import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';

/// Use case to remove a profile image
class RemoveProfileImageUseCase {
  final ProfileRepository _repository;

  RemoveProfileImageUseCase(this._repository);

  /// Remove the profile image
  Future<void> execute() async {
    return _repository.removeProfileImage();
  }
}
