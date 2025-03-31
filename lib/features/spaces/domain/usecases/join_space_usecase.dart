import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for joining a space
class JoinSpaceUseCase {
  final SpacesRepository repository;

  JoinSpaceUseCase(this.repository);

  /// Execute the use case to join a space
  Future<void> execute(String spaceId) {
    return repository.joinSpace(spaceId);
  }
}
