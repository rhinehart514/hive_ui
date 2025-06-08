import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Use case for updating a space's lifecycle state based on activity
class UpdateSpaceLifecycleUseCase {
  final SpacesRepository _repository;
  
  /// Constructor
  UpdateSpaceLifecycleUseCase(this._repository);
  
  /// Execute the use case to update the lifecycle state of a space
  /// Returns the updated space entity
  Future<SpaceEntity?> execute(String spaceId) async {
    try {
      // Get the space
      final space = await _repository.getSpaceById(spaceId);
      if (space == null) {
        return null;
      }
      
      // Update the lifecycle state based on activity
      final updatedSpace = space.updateLifecycleState();
      
      // If the state has changed, update the space in the repository
      if (updatedSpace.lifecycleState != space.lifecycleState) {
        // Update the space
        await _repository.updateSpace(updatedSpace);
      }
      
      return updatedSpace;
    } catch (e) {
      // Log error
      return null;
    }
  }
  
  /// Execute the use case for multiple spaces
  /// Returns a list of updated space entities
  Future<List<SpaceEntity>> executeMultiple(List<String> spaceIds) async {
    final results = <SpaceEntity>[];
    
    for (final spaceId in spaceIds) {
      final result = await execute(spaceId);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }
} 