import 'package:hive_ui/features/profile/domain/entities/profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';

/// Use case for retrieving a user's profile visibility settings
class GetProfileVisibilitySettings {
  /// The repository that this use case will use
  final ProfileVisibilityRepository repository;

  /// Constructor
  const GetProfileVisibilitySettings(this.repository);

  /// Call operator to execute the use case
  ///
  /// [userId] is the ID of the user whose settings to fetch
  Future<ProfileVisibilitySettings> call(String userId) async {
    return await repository.getVisibilitySettings(userId);
  }
} 