import 'dart:io';

import '../entities/space.dart';
import '../repositories/space_repository.dart';

/// Use case for creating a new space
class CreateSpaceUseCase {
  final SpaceRepository _spaceRepository;
  
  /// Constructor
  CreateSpaceUseCase(this._spaceRepository);
  
  /// Execute the use case to create a new space
  Future<bool> execute({
    required Space space,
    File? coverImage,
  }) async {
    // Business logic validation
    if (space.name.isEmpty) {
      throw Exception('Space name cannot be empty');
    }
    
    if (space.name.length < 3) {
      throw Exception('Space name must be at least 3 characters');
    }
    
    if (space.name.length > 50) {
      throw Exception('Space name must be less than 50 characters');
    }
    
    // Check if the space name is available
    final isNameAvailable = await _spaceRepository.isSpaceNameAvailable(space.name);
    if (!isNameAvailable) {
      throw Exception('Space name is already taken');
    }
    
    // Create the space
    return await _spaceRepository.createSpace(space, coverImage: coverImage);
  }
} 