import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/profile/data/datasources/profile_visibility_remote_datasource.dart';
import 'package:hive_ui/features/profile/data/repositories/profile_visibility_repository_impl.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_visibility_repository.dart';
import 'package:hive_ui/features/profile/domain/usecases/check_profile_feature_visibility.dart';
import 'package:hive_ui/features/profile/domain/usecases/get_profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/domain/usecases/update_profile_visibility_settings.dart';
import 'package:hive_ui/features/profile/presentation/controllers/profile_visibility_controller.dart';

/// Provider for the profile visibility remote data source
final profileVisibilityRemoteDataSourceProvider = Provider<ProfileVisibilityRemoteDataSource>((ref) {
  return ProfileVisibilityRemoteDataSource();
});

/// Provider for the profile visibility repository
final profileVisibilityRepositoryProvider = Provider<ProfileVisibilityRepository>((ref) {
  final dataSource = ref.watch(profileVisibilityRemoteDataSourceProvider);
  return ProfileVisibilityRepositoryImpl(dataSource);
});

/// Provider for the get profile visibility settings use case
final getProfileVisibilitySettingsProvider = Provider<GetProfileVisibilitySettings>((ref) {
  final repository = ref.watch(profileVisibilityRepositoryProvider);
  return GetProfileVisibilitySettings(repository);
});

/// Provider for the update profile visibility settings use case
final updateProfileVisibilitySettingsProvider = Provider<UpdateProfileVisibilitySettings>((ref) {
  final repository = ref.watch(profileVisibilityRepositoryProvider);
  return UpdateProfileVisibilitySettings(repository);
});

/// Provider for the check profile feature visibility use case
final checkProfileFeatureVisibilityProvider = Provider<CheckProfileFeatureVisibility>((ref) {
  final repository = ref.watch(profileVisibilityRepositoryProvider);
  return CheckProfileFeatureVisibility(repository);
});

/// Provider for the profile visibility controller
final profileVisibilityControllerProvider = ChangeNotifierProvider<ProfileVisibilityController>((ref) {
  return ProfileVisibilityController(
    getSettings: ref.watch(getProfileVisibilitySettingsProvider),
    updateSettings: ref.watch(updateProfileVisibilitySettingsProvider),
    checkFeatureVisibility: ref.watch(checkProfileFeatureVisibilityProvider),
  );
});

/// Provider to check if a specific profile feature is visible to the current user
final featureVisibilityProvider = FutureProvider.family<bool, FeatureVisibilityParams>((ref, params) async {
  final controller = ref.watch(profileVisibilityControllerProvider);
  return await controller.isFeatureVisibleTo(
    profileId: params.profileId,
    viewerId: params.viewerId,
    feature: params.feature,
  );
});

/// Parameters for checking feature visibility
class FeatureVisibilityParams {
  /// ID of the profile being viewed
  final String profileId;
  
  /// ID of the user viewing the profile
  final String viewerId;
  
  /// The feature to check visibility for
  final ProfileFeature feature;

  /// Constructor
  const FeatureVisibilityParams({
    required this.profileId,
    required this.viewerId,
    required this.feature,
  });
} 