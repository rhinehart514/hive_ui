import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for retrieving spaces joined by the current user
class GetJoinedSpacesUseCase {
  final SpacesRepository repository;

  GetJoinedSpacesUseCase(this.repository);

  /// Execute the use case to get joined spaces
  Future<List<SpaceEntity>> execute() {
    return repository.getJoinedSpaces();
  }
}
