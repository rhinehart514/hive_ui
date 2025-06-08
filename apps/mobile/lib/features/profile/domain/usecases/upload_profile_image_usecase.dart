import 'dart:io';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';

/// Use case to upload a profile image
class UploadProfileImageUseCase {
  final ProfileRepository _repository;

  UploadProfileImageUseCase(this._repository);

  /// Upload a profile image and return the URL
  Future<String> execute(File imageFile) async {
    return _repository.uploadProfileImage(imageFile);
  }
}
