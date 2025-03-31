import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for leaving a space
class LeaveSpaceUseCase {
  final SpacesRepository repository;

  LeaveSpaceUseCase(this.repository);

  /// Execute the use case to leave a space
  Future<void> execute(String spaceId) {
    return repository.leaveSpace(spaceId);
  }
}
