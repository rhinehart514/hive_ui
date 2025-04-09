import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/application/analytics_service.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_data_source.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/entities/space_entity.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/usecases/get_all_spaces_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/get_joined_spaces_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/join_space_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/leave_space_usecase.dart';
import 'package:hive_ui/features/spaces/domain/usecases/search_spaces_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Analytics service provider
final spacesAnalyticsServiceProvider = Provider<SpacesAnalyticsService>((ref) {
  return SpacesAnalyticsService();
});

// Data source provider
final spacesDataSourceProvider = Provider<SpacesDataSource>((ref) {
  return SpacesFirestoreDataSource();
});

// Repository provider
final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  final dataSource = ref.watch(spacesDataSourceProvider);
  final auth = FirebaseAuth.instance;
  return SpacesRepositoryImpl(dataSource, auth: auth);
});

// Use case providers
final getAllSpacesUseCaseProvider = Provider<GetAllSpacesUseCase>((ref) {
  final repository = ref.watch(spacesRepositoryProvider);
  return GetAllSpacesUseCase(repository);
});

final getJoinedSpacesUseCaseProvider = Provider<GetJoinedSpacesUseCase>((ref) {
  final repository = ref.watch(spacesRepositoryProvider);
  return GetJoinedSpacesUseCase(repository);
});

final joinSpaceUseCaseProvider = Provider<JoinSpaceUseCase>((ref) {
  final repository = ref.watch(spacesRepositoryProvider);
  return JoinSpaceUseCase(repository);
});

final leaveSpaceUseCaseProvider = Provider<LeaveSpaceUseCase>((ref) {
  final repository = ref.watch(spacesRepositoryProvider);
  return LeaveSpaceUseCase(repository);
});

final searchSpacesUseCaseProvider = Provider<SearchSpacesUseCase>((ref) {
  final repository = ref.watch(spacesRepositoryProvider);
  return SearchSpacesUseCase(repository);
});

// State providers for UI
final spacesLoadingProvider = StateProvider<bool>((ref) => false);
final spacesErrorProvider = StateProvider<String?>((ref) => null);

// All spaces provider
final allSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final useCase = ref.watch(getAllSpacesUseCaseProvider);
  ref.watch(spacesLoadingProvider.notifier).state = true;
  ref.watch(spacesErrorProvider.notifier).state = null;

  try {
    final spaces = await useCase.execute();
    ref.watch(spacesLoadingProvider.notifier).state = false;
    return spaces;
  } catch (e) {
    ref.watch(spacesLoadingProvider.notifier).state = false;
    ref.watch(spacesErrorProvider.notifier).state = e.toString();
    return [];
  }
});

// Joined spaces provider
final joinedSpacesProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final useCase = ref.watch(getJoinedSpacesUseCaseProvider);
  ref.watch(spacesLoadingProvider.notifier).state = true;
  ref.watch(spacesErrorProvider.notifier).state = null;

  try {
    final spaces = await useCase.execute();
    ref.watch(spacesLoadingProvider.notifier).state = false;
    return spaces;
  } catch (e) {
    ref.watch(spacesLoadingProvider.notifier).state = false;
    ref.watch(spacesErrorProvider.notifier).state = e.toString();
    return [];
  }
});

// Search query provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results provider
final searchResultsProvider = FutureProvider<List<SpaceEntity>>((ref) async {
  final query = ref.watch(searchQueryProvider);

  if (query.isEmpty) {
    return [];
  }

  final useCase = ref.watch(searchSpacesUseCaseProvider);
  ref.watch(spacesLoadingProvider.notifier).state = true;
  ref.watch(spacesErrorProvider.notifier).state = null;

  try {
    final spaces = await useCase.execute(query);
    ref.watch(spacesLoadingProvider.notifier).state = false;
    return spaces;
  } catch (e) {
    ref.watch(spacesLoadingProvider.notifier).state = false;
    ref.watch(spacesErrorProvider.notifier).state = e.toString();
    return [];
  }
});

// Selected space provider
final selectedSpaceIdProvider = StateProvider<String?>((ref) => null);

// Selected space provider
final selectedSpaceProvider = FutureProvider<SpaceEntity?>((ref) async {
  final spaceId = ref.watch(selectedSpaceIdProvider);

  if (spaceId == null) {
    return null;
  }

  final repository = ref.watch(spacesRepositoryProvider);
  return repository.getSpaceById(spaceId);
});

// Filter provider for space discovery
final spaceFilterProvider = StateProvider<String?>((ref) => null);

// Filtered spaces provider
final filteredSpacesProvider = Provider<List<SpaceEntity>>((ref) {
  final allSpacesAsync = ref.watch(allSpacesProvider);
  final filter = ref.watch(spaceFilterProvider);

  return allSpacesAsync.when(
    data: (spaces) {
      if (filter == null || filter.isEmpty) {
        return spaces;
      }

      return spaces
          .where((space) =>
              space.tags.contains(filter.toLowerCase()) ||
              space.spaceType
                  .toString()
                  .toLowerCase()
                  .contains(filter.toLowerCase()))
          .toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
