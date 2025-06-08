import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source_impl.dart';
import 'package:hive_ui/features/spaces/data/repositories/spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Provider for the spaces repository
final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  final dataSource = ref.watch(spacesDataSourceProvider);
  return SpacesRepositoryImpl(dataSource);
});

/// Provider for the spaces data source
final spacesDataSourceProvider = Provider<SpacesDataSource>((ref) {
  return SpacesDataSourceImpl();
});

/// Provider for all spaces from the repository
final allSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getAllSpaces(includePrivate: false, includeJoined: false);
});

/// Provider for joined spaces
final joinedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getJoinedSpaces();
});

/// Provider for trending spaces
final trendingSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getTrendingSpaces();
});

/// Provider for spaces with upcoming events
final upcomingEventsSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getSpacesWithUpcomingEvents();
});

/// Provider for a specific space by ID
final spaceByIdProvider = FutureProvider.family<SpaceEntity?, String>((ref, id) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getSpaceById(id);
});

/// Provider to check if a user has joined a space
final hasJoinedSpaceProvider = FutureProvider.family<bool, String>((ref, spaceId) async {
  final repository = ref.watch(spacesRepositoryProvider);
  return repository.hasJoinedSpace(spaceId);
});
