import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for leaving a space
class LeaveSpaceUseCase {
  final SpacesRepository repository;

  LeaveSpaceUseCase(this.repository);

  /// Execute the use case to leave a space
  /// 
  /// [spaceId] The ID of the space to leave
  /// [userId] Optional user ID to leave on behalf of. If not provided, uses the current user.
  /// 
  /// Returns true if successful, false otherwise.
  Future<bool> execute(String spaceId, {String? userId}) {
    return repository.leaveSpace(spaceId, userId: userId);
  }
}
