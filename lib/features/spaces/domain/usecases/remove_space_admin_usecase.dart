import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Use case for removing admin status from a user in a space
class RemoveSpaceAdminUseCase {
  final SpacesRepository _spacesRepository;

  RemoveSpaceAdminUseCase({
    required SpacesRepository spacesRepository,
  }) : _spacesRepository = spacesRepository;

  /// Remove admin status from a user
  ///
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to demote
  ///
  /// Returns true if successful, false otherwise
  Future<bool> execute(String spaceId, String userId) async {
    try {
      // Get the space to verify the user is an admin
      final space = await _spacesRepository.getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      if (!space.admins.contains(userId)) {
        throw Exception('User is not an admin of the space');
      }

      // Now remove the user as an admin
      final success = await _spacesRepository.removeAdmin(spaceId, userId);
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for RemoveSpaceAdminUseCase
final removeSpaceAdminUseCaseProvider = Provider<RemoveSpaceAdminUseCase>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  
  return RemoveSpaceAdminUseCase(
    spacesRepository: spacesRepository,
  );
}); 