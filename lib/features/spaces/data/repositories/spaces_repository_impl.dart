import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_ui/models/event.dart';

/// Implementation of the SpacesRepository interface
class SpacesRepositoryImpl implements SpacesRepository {
  final SpacesFirestoreDataSource _dataSource;

  /// Constructor
  SpacesRepositoryImpl(this._dataSource);

  @override
  Future<List<SpaceEntity>> getAllSpaces({
    bool forceRefresh = false,
    bool includePrivate = false,
    bool includeJoined = true,
  }) async {
    final spaces = await _dataSource.getAllSpaces(
      forceRefresh: forceRefresh,
      includePrivate: includePrivate,
      includeJoined: includeJoined,
    );
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SpaceEntity?> getSpaceById(String id, {String? spaceType}) async {
    try {
      final space = await _dataSource.getSpaceById(id, spaceType: spaceType);
      return space?.toEntity();
    } catch (e) {
      debugPrint('Error getting space by ID: $e');
      return null;
    }
  }

  @override
  Future<List<SpaceEntity>> getSpacesByCategory(String category) async {
    final spaces = await _dataSource.getSpacesByCategory(category);
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> getJoinedSpaces() async {
    final spaces = await _dataSource.getJoinedSpaces();
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> getRecommendedSpaces() async {
    final spaces = await _dataSource.getRecommendedSpaces();
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> searchSpaces(String query) async {
    final spaces = await _dataSource.searchSpaces(query);
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> joinSpace(String spaceId) {
    return _dataSource.joinSpace(spaceId);
  }

  @override
  Future<void> leaveSpace(String spaceId) {
    return _dataSource.leaveSpace(spaceId);
  }

  @override
  Future<bool> hasJoinedSpace(String spaceId) {
    return _dataSource.hasJoinedSpace(spaceId);
  }

  @override
  Future<List<SpaceEntity>> getSpacesWithUpcomingEvents() async {
    final spaces = await _dataSource.getSpacesWithUpcomingEvents();
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<List<SpaceEntity>> getTrendingSpaces() async {
    final spaces = await _dataSource.getTrendingSpaces();
    return spaces.map((model) => model.toEntity()).toList();
  }

  @override
  Future<SpaceEntity> createSpace({
    required String name,
    required String description,
    required int iconCodePoint,
    required SpaceType spaceType,
    required List<String> tags,
    required bool isPrivate,
    required String creatorId,
    bool isHiveExclusive = true,
  }) async {
    final space = await _dataSource.createSpace(
      name: name,
      description: description,
      iconCodePoint: iconCodePoint,
      spaceType: spaceType,
      tags: tags,
      isPrivate: isPrivate,
      creatorId: creatorId,
      isHiveExclusive: isHiveExclusive,
    );
    
    return space.toEntity();
  }

  @override
  Future<bool> isSpaceNameTaken(String name) {
    return _dataSource.isSpaceNameTaken(name);
  }

  @override
  Future<List<Event>> getSpaceEvents(String spaceId) async {
    try {
      final events = await _dataSource.getSpaceEvents(spaceId);
      return events;
    } catch (e) {
      debugPrint('Error getting space events: $e');
      return [];
    }
  }
}
