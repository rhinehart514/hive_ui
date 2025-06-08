import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';

/// Use case for promoting a member to admin in a space
class MakeSpaceAdminUseCase {
  final SpacesRepository _spacesRepository;

  MakeSpaceAdminUseCase({
    required SpacesRepository spacesRepository,
  }) : _spacesRepository = spacesRepository;

  /// Promote a member to admin
  ///
  /// [spaceId] The ID of the space
  /// [userId] The ID of the user to promote
  ///
  /// Returns true if successful, false otherwise
  Future<bool> execute(String spaceId, String userId) async {
    try {
      // First check if the user is a member of the space
      final memberIds = await _spacesRepository.getSpaceMembers(spaceId);
      if (!memberIds.contains(userId)) {
        throw Exception('User is not a member of the space');
      }

      // Now add the user as an admin
      final success = await _spacesRepository.addAdmin(spaceId, userId);
      return success;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for MakeSpaceAdminUseCase
final makeSpaceAdminUseCaseProvider = Provider<MakeSpaceAdminUseCase>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  
  return MakeSpaceAdminUseCase(
    spacesRepository: spacesRepository,
  );
}); 