import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';

/// Use case for checking if a profile feature is visible to another user
class CheckProfileFeatureVisibility {
  /// The repository that this use case will use
  final ProfileVisibilityRepository repository;

  /// Constructor
  const CheckProfileFeatureVisibility(this.repository);

  /// Call operator to execute the use case
  ///
  /// [profileId] is the ID of the profile being viewed
  /// [viewerId] is the ID of the user trying to view the profile
  /// [feature] is the specific profile feature being checked
  Future<bool> call({
    required String profileId,
    required String viewerId,
    required ProfileFeature feature,
  }) async {
    // If the viewer is the profile owner, always return true
    if (profileId == viewerId) {
      return true;
    }
    
    return await repository.isFeatureVisibleTo(profileId, viewerId, feature);
  }
} 