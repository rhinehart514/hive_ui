import 'dart:io';

import '../entities/space.dart';
import '../entities/space_entity.dart' as entity;
import '../entities/space_metrics_entity.dart';
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
    
    // Convert Space to SpaceEntity
    final spaceEntity = _convertToSpaceEntity(space);
    
    // Create the space
    return await _spaceRepository.createSpace(spaceEntity, coverImage: coverImage);
  }
  
  /// Helper method to convert Space to SpaceEntity
  entity.SpaceEntity _convertToSpaceEntity(Space space) {
    // Convert privacy enum to boolean
    final isPrivate = space.privacy == SpacePrivacy.private;
    
    // Set appropriate space type
    entity.SpaceType spaceType;
    switch (space.type) {
      case SpaceType.academic:
        spaceType = entity.SpaceType.studentOrg;
        break;
      case SpaceType.club:
        spaceType = entity.SpaceType.universityOrg;
        break;
      case SpaceType.hiveExclusive:
        spaceType = entity.SpaceType.hiveExclusive;
        break;
      case SpaceType.community:
      case SpaceType.event:
      default:
        spaceType = entity.SpaceType.other;
        break;
    }
    
    return entity.SpaceEntity(
      id: space.id,
      name: space.name,
      description: space.description,
      iconCodePoint: 0xe491, // Default icon code
      imageUrl: space.coverImageUrl,
      bannerUrl: space.coverImageUrl,
      metrics: SpaceMetricsEntity.empty(),
      tags: space.tags,
      isPrivate: isPrivate,
      admins: [space.ownerId],
      createdAt: space.createdAt,
      updatedAt: DateTime.now(),
      spaceType: spaceType,
      hiveExclusive: space.type == SpaceType.hiveExclusive,
    );
  }
} 