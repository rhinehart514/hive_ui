import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for retrieving all spaces
class GetAllSpacesUseCase {
  final SpacesRepository repository;

  GetAllSpacesUseCase(this.repository);

  /// Execute the use case to get all spaces
  Future<List<SpaceEntity>> execute({bool forceRefresh = false}) {
    return repository.getAllSpaces(forceRefresh: forceRefresh);
  }
}
