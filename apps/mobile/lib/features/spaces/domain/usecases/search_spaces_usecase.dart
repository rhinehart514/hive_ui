import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for searching spaces by query text
class SearchSpacesUseCase {
  final SpacesRepository repository;

  SearchSpacesUseCase(this.repository);

  /// Execute the use case to search spaces
  Future<List<SpaceEntity>> execute(String query) {
    return repository.searchSpaces(query);
  }
}
