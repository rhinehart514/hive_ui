import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for joining a space
class JoinSpaceUseCase {
  final SpacesRepository repository;

  JoinSpaceUseCase(this.repository);

  /// Execute the use case to join a space
  /// 
  /// [spaceId] The ID of the space to join
  /// [userId] Optional user ID to join on behalf of. If not provided, uses the current user.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> execute(String spaceId, {String? userId}) {
    return repository.joinSpace(spaceId, userId: userId);
  }
}
