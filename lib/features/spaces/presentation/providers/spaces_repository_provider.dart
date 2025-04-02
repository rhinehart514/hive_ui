import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';
import 'package:hive_ui/features/spaces/domain/repositories/space_repository.dart';
import 'package:hive_ui/features/spaces/data/repositories/space_repository_impl.dart';
import 'package:hive_ui/core/services/firebase/firebase_services.dart';

/// Provider for SpacesFirestoreDataSource
final spacesFirestoreDataSourceProvider = Provider<SpacesFirestoreDataSource>((ref) {
  // Ensure Firebase is initialized
  ref.watch(firebaseCoreServiceProvider).isInitialized;
  return SpacesFirestoreDataSource();
});

/// Provider for SpacesRepository
final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  // Ensure Firebase is initialized
  ref.watch(firebaseCoreServiceProvider).isInitialized;
  final dataSource = ref.watch(spacesFirestoreDataSourceProvider);
  return SpacesRepositoryImpl(dataSource);
});

/// Provider for the space repository
final spaceRepositoryProvider = Provider<SpaceRepository>((ref) {
  // Ensure Firebase is initialized
  ref.watch(firebaseCoreServiceProvider).isInitialized;
  return SpaceRepositoryImpl();
}); 