import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';

/// Use case for updating a user's profile visibility settings
class UpdateProfileVisibilitySettings {
  /// The repository that this use case will use
  final ProfileVisibilityRepository repository;

  /// Constructor
  const UpdateProfileVisibilitySettings(this.repository);

  /// Call operator to execute the use case
  ///
  /// [settings] contains the updated visibility settings to save
  Future<void> call(ProfileVisibilitySettings settings) async {
    await repository.updateVisibilitySettings(settings);
  }
} 