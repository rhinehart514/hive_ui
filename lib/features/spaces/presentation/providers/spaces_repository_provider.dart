import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ui/features/spaces/data/datasources/spaces_firestore_datasource.dart';
import 'package:hive_ui/features/spaces/data/repositories/spaces_repository_impl.dart';
import 'package:hive_ui/features/spaces/domain/repositories/spaces_repository.dart';

/// Provider for SpacesFirestoreDataSource
final spacesFirestoreDataSourceProvider = Provider<SpacesFirestoreDataSource>((ref) {
  return SpacesFirestoreDataSource();
});

/// Provider for SpacesRepository
final spacesRepositoryProvider = Provider<SpacesRepository>((ref) {
  final dataSource = ref.watch(spacesFirestoreDataSourceProvider);
  return SpacesRepositoryImpl(dataSource);
}); 