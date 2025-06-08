import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/profile/domain/repositories/profile_repository.dart';
import 'package:hive_ui/features/profile/domain/entities/user_profile.dart';
import 'package:hive_ui/features/spaces/presentation/providers/spaces_repository_provider.dart';
import 'package:hive_ui/features/profile/presentation/providers/profile_providers.dart';

/// Use case for getting members of a space with their profiles
class GetSpaceMembersUseCase {
  final SpacesRepository _spacesRepository;
  final ProfileRepository _profileRepository;

  GetSpaceMembersUseCase({
    required SpacesRepository spacesRepository,
    required ProfileRepository profileRepository,
  })  : _spacesRepository = spacesRepository,
        _profileRepository = profileRepository;

  /// Get all members of a space with their profiles
  ///
  /// [spaceId] The ID of the space to get members for
  ///
  /// Returns a list of user profiles for space members
  Future<List<UserProfile>> execute(String spaceId) async {
    try {
      // Get member IDs from space repository
      final memberIds = await _spacesRepository.getSpaceMembers(spaceId);
      
      if (memberIds.isEmpty) {
        return [];
      }
      
      // Get space entity to check for admins
      final space = await _spacesRepository.getSpaceById(spaceId);
      if (space == null) {
        throw Exception('Space not found');
      }
      
      // Get individual profiles
      final profiles = <UserProfile>[];
      for (final memberId in memberIds) {
        final profile = await _profileRepository.getProfile(memberId);
        if (profile != null) {
          profiles.add(profile);
        }
      }
      
      // Return profiles
      return profiles;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }
}

/// Provider for GetSpaceMembersUseCase
final getSpaceMembersUseCaseProvider = Provider<GetSpaceMembersUseCase>((ref) {
  final spacesRepository = ref.watch(spacesRepositoryProvider);
  final profileRepository = ref.watch(profileRepositoryProvider);
  
  return GetSpaceMembersUseCase(
    spacesRepository: spacesRepository,
    profileRepository: profileRepository,
  );
}); 