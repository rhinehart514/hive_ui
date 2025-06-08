import 'dart:io';

import '../entities/space.dart';
import '../entities/space_entity.dart' as entity;
import '../entities/space_metrics_entity.dart';
import '../repositories/spaces_repository.dart';
import 'package:flutter/foundation.dart';

/// Use case for creating a new space
class CreateSpaceUseCase {
  final SpacesRepository _spaceRepository;
  
  /// Constructor
  CreateSpaceUseCase(this._spaceRepository);
  
  /// Execute the use case to create a new space
  Future<bool> execute({
    required Space space,
    File? coverImage,
    SpacePrivacy privacy = SpacePrivacy.public,
    SpaceType spaceType = SpaceType.community,
    List<String> tags = const [],
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
    final isNameTaken = await _spaceRepository.isSpaceNameTaken(space.name);
    if (isNameTaken) {
      throw Exception('Space name is already taken');
    }
    
    // Convert Space to SpaceEntity for parameter extraction
    final spaceEntity = _convertToSpaceEntity(
      space, 
      privacy: privacy, 
      spaceType: spaceType, 
      tags: tags
    );
    
    // Create the space using the new interface
    try {
      await _spaceRepository.createSpace(
        name: spaceEntity.name,
        description: spaceEntity.description,
        iconCodePoint: spaceEntity.iconCodePoint,
        spaceType: spaceEntity.spaceType,
        tags: spaceEntity.tags,
        isPrivate: spaceEntity.isPrivate,
        creatorId: spaceEntity.admins.isNotEmpty ? spaceEntity.admins.first : '',
        isHiveExclusive: spaceEntity.hiveExclusive,
        coverImage: coverImage,
      );
      return true;
    } catch (e) {
      debugPrint('Error creating space: $e');
      return false;
    }
  }
  
  /// Helper method to convert Space to SpaceEntity
  entity.SpaceEntity _convertToSpaceEntity(
    Space space, {
    required SpacePrivacy privacy,
    required SpaceType spaceType,
    required List<String> tags,
  }) {
    // Convert privacy enum to boolean
    final isPrivate = privacy == SpacePrivacy.private;
    
    // Set appropriate space type
    entity.SpaceType entitySpaceType;
    switch (spaceType) {
      case SpaceType.academic:
        entitySpaceType = entity.SpaceType.studentOrg;
        break;
      case SpaceType.club:
        entitySpaceType = entity.SpaceType.universityOrg;
        break;
      case SpaceType.hiveExclusive:
        entitySpaceType = entity.SpaceType.hiveExclusive;
        break;
      case SpaceType.community:
      case SpaceType.event:
      default:
        entitySpaceType = entity.SpaceType.other;
        break;
    }
    
    return entity.SpaceEntity(
      id: space.id,
      name: space.name,
      description: space.description,
      iconCodePoint: 0xe491, // Default icon code
      imageUrl: space.imageUrl,
      bannerUrl: space.imageUrl,
      metrics: SpaceMetricsEntity.empty(),
      tags: tags,
      isPrivate: isPrivate,
      admins: [space.ownerId],
      createdAt: space.createdAt,
      updatedAt: DateTime.now(),
      spaceType: entitySpaceType,
      hiveExclusive: spaceType == SpaceType.hiveExclusive,
    );
  }
} 