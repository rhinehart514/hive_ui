import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/models/user_profile.dart' as model;
import 'package:hive_ui/features/profile/data/mappers/user_profile_mapper.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/usecases/get_space_members_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/make_space_admin_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/remove_space_admin_usecase.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Provider for space members for a specific space
final spaceMembersProvider = FutureProvider.family<List<model.UserProfile>, String>((ref, spaceId) async {
  final getMembersUseCase = ref.watch(getSpaceMembersUseCaseProvider);
  final domainProfiles = await getMembersUseCase.execute(spaceId);
  
  // Convert domain profiles to model profiles
  return UserProfileMapper.mapListToModel(domainProfiles);
});

/// State for member management operations
enum MemberOperationState { idle, loading, success, error }

/// Provider for the current member operation state
final memberOperationStateProvider = StateProvider<MemberOperationState>((ref) {
  return MemberOperationState.idle;
});

/// Provider for any error message during member operations
final memberOperationErrorProvider = StateProvider<String?>((ref) {
  return null;
});

/// Provider to check if a user is an admin of a space
final isUserSpaceAdminProvider = FutureProvider.family<bool, ({String userId, String spaceId})>((ref, params) async {
  final space = await ref.watch(spaceProvider(params.spaceId).future);
  return space?.admins.contains(params.userId) ?? false;
});

/// Function to promote a user to admin
Future<bool> makeUserAdmin(WidgetRef ref, String spaceId, String userId) async {
  ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.loading;
  ref.read(memberOperationErrorProvider.notifier).state = null;

  try {
    final makeAdminUseCase = ref.read(makeSpaceAdminUseCaseProvider);
    final success = await makeAdminUseCase.execute(spaceId, userId);

    if (success) {
      ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.success;
      // Invalidate relevant providers to refresh data
      ref.invalidate(spaceMembersProvider(spaceId));
      ref.invalidate(spaceProvider(spaceId));
      return true;
    } else {
      ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.error;
      ref.read(memberOperationErrorProvider.notifier).state = 'Failed to make user an admin';
      return false;
    }
  } catch (e) {
    ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.error;
    ref.read(memberOperationErrorProvider.notifier).state = e.toString();
    return false;
  }
}

/// Function to remove admin status from a user
Future<bool> removeUserAdmin(WidgetRef ref, String spaceId, String userId) async {
  ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.loading;
  ref.read(memberOperationErrorProvider.notifier).state = null;

  try {
    final removeAdminUseCase = ref.read(removeSpaceAdminUseCaseProvider);
    final success = await removeAdminUseCase.execute(spaceId, userId);

    if (success) {
      ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.success;
      // Invalidate relevant providers to refresh data
      ref.invalidate(spaceMembersProvider(spaceId));
      ref.invalidate(spaceProvider(spaceId));
      return true;
    } else {
      ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.error;
      ref.read(memberOperationErrorProvider.notifier).state = 'Failed to remove admin status';
      return false;
    }
  } catch (e) {
    ref.read(memberOperationStateProvider.notifier).state = MemberOperationState.error;
    ref.read(memberOperationErrorProvider.notifier).state = e.toString();
    return false;
  }
}

/// Provider for the selected space
final spaceProvider = FutureProvider.family<SpaceEntity?, String>((ref, spaceId) async {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  return spacesRepository.getSpaceById(spaceId);
}); 